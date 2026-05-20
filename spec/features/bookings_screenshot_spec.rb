# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bookings calendar screenshot", type: :feature, js: true do
  before { Capybara.current_driver = :headless_chrome }
  after  { Capybara.use_default_driver }

  let(:today) { Date.new(2026, 5, 20) }

  around do |example|
    travel_to(today.beginning_of_day) { example.run }
  end

  before do
    Booking.create!(guest_name: "Alice Smith",   room_number: 101, check_in: today - 2.days, check_out: today + 1.day)
    Booking.create!(guest_name: "Bob Garcia",    room_number: 202, check_in: today + 2.days, check_out: today + 3.days)
    Booking.create!(guest_name: "Carol Yang",    room_number: 101, check_in: today - 6.days, check_out: today - 1.day)
    Booking.create!(guest_name: "Diana Park",    room_number: 303, check_in: today + 5.days, check_out: today + 8.days)
    Booking.create!(guest_name: "Erik Müller",   room_number: 404, check_in: today - 4.days, check_out: today + 2.days)
  end

  it "captures the bookings calendar with fan-out across days" do
    visit "/admin/bookings"
    expect(page).to have_css("table#index_calendar")
    take_screenshot("bookings_calendar_#{aa_major_version}")
  end

  def aa_major_version
    Gem::Version.new(ActiveAdmin::VERSION).segments.first(2).join("_")
  end
end
