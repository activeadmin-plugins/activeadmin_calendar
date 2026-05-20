# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bookings calendar (group_by_scope use case)", type: :feature do
  let(:today) { Date.new(2026, 5, 20) }

  around do |example|
    travel_to(today.beginning_of_day) { example.run }
  end

  # Alice Smith: 3-night stay, check-in May 18, check-out May 21 — active on 18/19/20
  # Bob Garcia:  1-night stay on May 22 — active on May 22 only
  # Carol Yang:  5-night stay May 14 → check-out May 19 — active on 14/15/16/17/18
  let!(:alice) { Booking.create!(guest_name: "Alice Smith", room_number: 101, check_in: today - 2.days, check_out: today + 1.day) }
  let!(:bob)   { Booking.create!(guest_name: "Bob Garcia",  room_number: 202, check_in: today + 2.days, check_out: today + 3.days) }
  let!(:carol) { Booking.create!(guest_name: "Carol Yang",  room_number: 101, check_in: today - 6.days, check_out: today - 1.day) }

  before { visit "/admin/bookings" }

  describe "fan-out across days" do
    it "the same booking appears on every active day" do
      [today - 2.days, today - 1.day, today].each do |d|
        cell = find(".day", text: d.day.to_s).find(:xpath, "..")
        expect(cell).to have_text("#101 Alice Smith"), "Alice expected on #{d}"
      end
    end

    it "renders arrow markers for first / middle / last night" do
      first_cell  = find(".day", text: (today - 2.days).day.to_s).find(:xpath, "..")
      middle_cell = find(".day", text: (today - 1.day).day.to_s).find(:xpath, "..")
      last_cell   = find(".day", text: today.day.to_s).find(:xpath, "..")

      expect(first_cell).to  have_text("→ #101 Alice Smith")
      expect(middle_cell).to have_text("· #101 Alice Smith")
      expect(last_cell).to   have_text("← #101 Alice Smith")
    end

    it "single-night bookings get a bullet marker on their one day" do
      cell = find(".day", text: (today + 2.days).day.to_s).find(:xpath, "..")
      expect(cell).to have_text("• #202 Bob Garcia")
    end

    it "booking does NOT appear on the check-out day itself (guest already left)" do
      checkout_cell = find(".day", text: (today + 1.day).day.to_s).find(:xpath, "..")
      expect(checkout_cell).not_to have_text("Alice Smith")
    end
  end

  describe "filtering" do
    it "filter by room_number narrows fan-out to that room only" do
      visit "/admin/bookings?q[room_number_eq]=202"

      cell = find(".day", text: (today + 2.days).day.to_s).find(:xpath, "..")
      expect(cell).to have_text("Bob Garcia")

      alice_day = find(".day", text: today.day.to_s).find(:xpath, "..")
      expect(alice_day).not_to have_text("Alice Smith")
      expect(alice_day).not_to have_text("Carol Yang")
    end

    it "filter by guest_name_cont leaves only matching bookings on each day" do
      visit "/admin/bookings?q[guest_name_cont]=Carol"

      carol_day = find(".day", text: (today - 3.days).day.to_s).find(:xpath, "..")
      expect(carol_day).to have_text("Carol Yang")

      empty_day = find(".day", text: (today + 2.days).day.to_s).find(:xpath, "..")
      expect(empty_day).not_to have_text("Bob Garcia")
    end
  end

  describe "query characteristics (per-cell, documented trade-off)" do
    it "issues one SELECT per day cell because group_by_scope is per-date" do
      queries = []
      ActiveSupport::Notifications.subscribed(
        ->(_n, _s, _f, _i, payload) {
          next if payload[:name] == "SCHEMA"
          queries << payload[:sql] if payload[:sql].start_with?("SELECT") && payload[:sql].include?("\"bookings\"")
        },
        "sql.active_record"
      ) do
        visit "/admin/bookings?year=2026&month=5"
      end

      # group_by_scope mode: 35 day cells = 35 selects (+ a default AA query).
      # This is the documented trade-off; users who need 1-query for a scope
      # should pre-fetch via controller#scoped_collection (see README).
      expect(queries.size).to be >= 35
    end
  end
end
