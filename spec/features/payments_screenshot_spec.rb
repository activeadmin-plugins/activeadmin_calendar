# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Payments calendar screenshot", type: :feature, js: true do
  before { Capybara.current_driver = :headless_chrome }
  after  { Capybara.use_default_driver }

  let(:today) { Date.new(2026, 5, 20) }

  around do |example|
    travel_to(today.beginning_of_day) { example.run }
  end

  before do
    Payment.create!(amount: 100,  card_type: "visa",       paid_at: today.beginning_of_day + 1.hour)
    Payment.create!(amount: 50,   card_type: "visa",       paid_at: today.beginning_of_day + 3.hours)
    Payment.create!(amount: 200,  card_type: "mastercard", paid_at: today.beginning_of_day + 5.hours)
    Payment.create!(amount: 75,   card_type: "amex",       paid_at: today.beginning_of_day - 6.hours)
    Payment.create!(amount: 320,  card_type: "visa",       paid_at: today.beginning_of_day + 2.days)
    Payment.create!(amount: 1200, card_type: "amex",       paid_at: today.beginning_of_day - 5.days)
  end

  it "captures the calendar with per-day card-type totals" do
    visit "/admin/payments"
    expect(page).to have_css("table#index_calendar")
    File.write("/tmp/cal4.html", page.html)
    take_screenshot("payments_calendar_#{aa_major_version}")
  end

  def aa_major_version
    Gem::Version.new(ActiveAdmin::VERSION).segments.first(2).join("_")
  end
end
