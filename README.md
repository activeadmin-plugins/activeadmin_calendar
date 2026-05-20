# activeadmin_calendar

Adds `index as: :calendar` to ActiveAdmin — renders the resource list as a
month grid with one cell per day. The index block is yielded `(date, records)`
for each day cell.

**Compatible with ActiveAdmin 3.5+ and 4.x.**

## Why

Built-in `index as: :table` is great for flat lists, but some resources are
inherently **date-bucketed**:

- Daily reports (spendings, payments, orders by day)
- Bookings / reservations spanning multiple days
- Scheduled tasks, campaigns, subscriptions with start/end dates
- Audit logs grouped by day

This gem gives you a month calendar with previous/next/today navigation, sub-CSS
that doesn't fight your AA theme, and **one SQL query per visible month** in
the common case (`group_by:` mode).

## Installation

```ruby
# Gemfile
gem "activeadmin_calendar"
```

For Sprockets (AA 3) add the stylesheet:

```scss
/* app/assets/stylesheets/active_admin.scss */
@import "activeadmin_calendar";
```

For Propshaft / Tailwind (AA 4) — the gem ships a plain CSS file under
`app/assets/stylesheets/activeadmin_calendar.css` that Propshaft picks up
automatically.

## Usage

### Single-date events (`group_by:`)

Use when each row belongs to one day — payments, orders, daily reports.
**1 SQL query** per month (prefetched).

```ruby
ActiveAdmin.register Payment do
  config.paginate = false
  actions :index

  filter :card_type, as: :select, collection: Payment::CARD_TYPES

  index as: :calendar, group_by: :paid_at do |date, payments|
    by_card = payments.group_by(&:card_type)
                      .transform_values { |ps| ps.sum(&:amount) }
    ul do
      by_card.each do |card, amount|
        li "#{card.upcase}: #{number_to_currency(amount)}"
      end
      total = by_card.values.sum
      li { strong "Total: #{number_to_currency(total)}" } unless total.zero?
    end
  end
end
```

### Range / fan-out events (`group_by_scope:`)

Use when one row spans multiple days — bookings, subscriptions, campaigns,
events active "between X and Y". **One SQL query per visible day cell** —
trade-off documented below.

```ruby
class Booking < ApplicationRecord
  # Active on every date in [check_in, check_out)
  scope :active_on, ->(date) { where("check_in <= ? AND check_out > ?", date, date) }
end

ActiveAdmin.register Booking do
  config.paginate = false
  filter :room_number
  filter :guest_name_cont, label: "Guest name contains"

  index as: :calendar, group_by_scope: :active_on do |date, bookings|
    ul do
      bookings.sort_by(&:room_number).each do |b|
        first = b.check_in == date
        last  = b.check_out - 1.day == date
        marker = first && last ? "•" : first ? "→" : last ? "←" : "·"
        li { text_node "#{marker} ##{b.room_number} #{b.guest_name}" }
      end
    end
  end
end
```

The same booking record shows up in every cell of its active range — May 18 →
21 booking appears on 18 (`→`), 19 (`·`), 20 (`←`).

## Options

| Option | Effect |
|---|---|
| `group_by:` (Symbol) | Column to bucket by, default `:updated_at`. Gem auto-prefetches all rows for the visible month grid in **one SQL query** and groups in Ruby. |
| `group_by_scope:` (Symbol) | Name of a scope `Model.scope(date)` to call per day cell. Use when bucketing needs custom SQL (range overlap, joins, time-zone conversion). **N queries per month** (one per visible cell). |
| `header:` (String / Proc) | Rendered next to the month title. Proc receives `(collection, current_month)`. |

URL params `?year=2026&month=5` drive the visible month; Today / Previous /
Next links are rendered automatically and **preserve current filter params**.

The index block receives `(date, scoped_for_day)`:
- With `group_by:` — `scoped_for_day` is an **Array** (pre-loaded subset).
- With `group_by_scope:` — `scoped_for_day` is an **ActiveRecord::Relation**.

## Filtering

Ransack filters work transparently — the gem starts from the AA-scoped
collection (`Resource.ransack(params[:q]).result`) and bucketizes inside that.
Test app:

```
GET /admin/payments?q[card_type_eq]=visa
→ today's cell shows only VISA: $150.00
```

## Query counts

| Mode | SQL per month |
|---|---|
| `group_by: :col` | **1** (prefetch + Ruby grouping) |
| `group_by_scope: :scope` | **35** (≈ visible day cells × 1) |

If you must use `group_by_scope:` AND need fewer queries, pre-fetch in your
controller and return a wrapper that responds to your scope name:

```ruby
controller do
  def scoped_collection
    base = super.where(spent_at: month_range)  # one SQL
    rows = base.to_a.group_by { |r| r.spent_at.to_date }
    PrefetchedScope.new(rows)
  end
end
```

## Testing

```ruby
RSpec.describe "Payments calendar" do
  let(:today) { Date.new(2026, 5, 20) }
  around { |ex| travel_to(today.beginning_of_day) { ex.run } }

  before { Payment.create!(amount: 100, card_type: "visa", paid_at: today) }

  it "renders today's cell" do
    visit "/admin/payments"
    within "table#index_calendar td.today" do
      expect(page).to have_text("VISA: $100.00")
    end
  end
end
```

`travel_to` (in an `around` hook) is necessary — the calendar uses
`Time.zone.now.to_date` to highlight `td.today` and to default the visible
month if `?year=&month=` are absent.

## Use cases

| Domain | Mode | Example block |
|---|---|---|
| Daily financial reports | `group_by:` | Group `Payment` by `card_type`, sum `amount` per day |
| Order history | `group_by:` | Show `Order` count per day with status breakdown |
| Audit logs | `group_by:` | Bucket `AuditEvent` by `occurred_at` |
| Hotel / coworking booking grid | `group_by_scope:` | Booking spans multi-night, fans out across `[check_in, check_out)` |
| Subscription lifecycle | `group_by_scope:` | Active customers per day (`started_on <= d AND ended_on > d`) |
| Marketing campaigns | `group_by_scope:` | Campaign visible on each day in `start_date..end_date` |
| Scheduled tasks | `group_by_scope:` | Recurring jobs that fire on certain dates |

## Styling

The bundled CSS is generic (no Sass / Tailwind dependency) — borders, grid
cells, today highlight, month nav buttons. To restyle, target:

```css
table#index_calendar tbody td.today { background: lemonchiffon; }
table#index_calendar tbody td.not_current_month { opacity: 0.4; }
```

In AA 4 a minor reset is included to remove the `.paginated-collection` panel
border around the calendar (the wrapper exists for tables, not calendars).

## How it works

`ActiveAdmin::Views::IndexAsCalendar` subclasses `ActiveAdmin::Component` and
registers `index_name "calendar"`. On build:

1. Computes `current_month` from `params[:year]`/`params[:month]` (defaults to
   `Time.zone.now`).
2. If `group_by:` is set, fires one `SELECT … WHERE col >= grid_start AND col < grid_end.tomorrow`
   and groups in Ruby into `Hash[Date → records]`.
3. Renders `<table id="index_calendar">` with one `<td>` per day cell (Mon..Sun
   layout), yields each day to the user block.

`group_by_scope:` mode bypasses prefetch — for each day cell the scope is
called with the date.

## License

MIT
