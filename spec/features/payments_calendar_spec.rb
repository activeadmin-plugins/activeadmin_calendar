# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Payments calendar grouped by card type", type: :feature do
  let(:today) { Date.new(2026, 5, 20) }

  around do |example|
    travel_to(today.beginning_of_day) { example.run }
  end

  let!(:visa_1)     { Payment.create!(amount: 100, card_type: "visa",       paid_at: today.beginning_of_day + 1.hour) }
  let!(:visa_2)     { Payment.create!(amount: 50,  card_type: "visa",       paid_at: today.beginning_of_day + 3.hours) }
  let!(:mastercard) { Payment.create!(amount: 200, card_type: "mastercard", paid_at: today.beginning_of_day + 5.hours) }
  let!(:amex_yest)  { Payment.create!(amount: 75,  card_type: "amex",       paid_at: today.beginning_of_day - 6.hours) }

  before { visit "/admin/payments" }

  it "renders the calendar shell with month header and navigation" do
    expect(page).to have_css("table#index_calendar")
    expect(page).to have_css("h2", text: today.strftime("%B %Y"))
    expect(page).to have_css("ul#index_calendar_nav li.today")
    expect(page).to have_css("ul#index_calendar_nav li.prev")
    expect(page).to have_css("ul#index_calendar_nav li.next")
  end

  it "today's cell aggregates two cards plus a total line" do
    within "table#index_calendar td.today" do
      expect(page).to have_css(".day", text: today.day.to_s)
      expect(page).to have_text("VISA: $150.00")
      expect(page).to have_text("MASTERCARD: $200.00")
      expect(page).to have_css("strong", text: "Total: $350.00")
    end
  end

  it "yesterday cell shows AMEX only" do
    yesterday = today - 1.day
    within "table#index_calendar" do
      day_cell = find(".day", text: yesterday.day.to_s).find(:xpath, "..")
      expect(day_cell).to have_text("AMEX: $75.00")
      expect(day_cell).not_to have_text("VISA")
    end
  end

  it "Previous link navigates to prior month" do
    click_link "Previous"
    expect(page).to have_css("h2", text: (today << 1).strftime("%B %Y"))
    expect(page).not_to have_text("VISA")
  end

  it "renders empty cells silently when no payments fall in a day" do
    visit "/admin/payments?year=2030&month=1"
    expect(page).to have_css("h2", text: "January 2030")
    expect(page).not_to have_text("VISA")
    expect(page).not_to have_text("MASTERCARD")
  end

  describe "filtering by card type" do
    it "VISA filter narrows today's cell to VISA only" do
      visit "/admin/payments?q[card_type_eq]=visa"

      within "table#index_calendar td.today" do
        expect(page).to have_text("VISA: $150.00")
        expect(page).to have_css("strong", text: "Total: $150.00")
        expect(page).not_to have_text("MASTERCARD")
      end
    end

    it "AMEX filter shows only yesterday's amex payment, hides today entirely" do
      visit "/admin/payments?q[card_type_eq]=amex"

      yesterday = today - 1.day
      yesterday_cell = find(".day", text: yesterday.day.to_s).find(:xpath, "..")
      expect(yesterday_cell).to have_text("AMEX: $75.00")
      expect(yesterday_cell).to have_css("strong", text: "Total: $75.00")

      within "table#index_calendar td.today" do
        expect(page).not_to have_text("VISA")
        expect(page).not_to have_text("MASTERCARD")
        expect(page).not_to have_text("AMEX")
      end
    end

    it "MASTERCARD filter shows only the mastercard payment in today's cell" do
      visit "/admin/payments?q[card_type_eq]=mastercard"

      within "table#index_calendar td.today" do
        expect(page).to have_text("MASTERCARD: $200.00")
        expect(page).to have_css("strong", text: "Total: $200.00")
        expect(page).not_to have_text("VISA")
      end
    end

    it "filter UI preserves selection and month nav links carry the filter" do
      visit "/admin/payments?q[card_type_eq]=amex"

      within "ul#index_calendar_nav li.prev a" do
        expect(page.find(:xpath, ".")["href"]).to include("q[card_type_eq]=amex").or include("q%5Bcard_type_eq%5D=amex")
      end
    end
  end
end
