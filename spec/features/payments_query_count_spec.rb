# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Payments calendar query count", type: :feature do
  let(:today) { Date.new(2026, 5, 20) }

  around do |example|
    travel_to(today.beginning_of_day) { example.run }
  end

  before { Payment.create!(amount: 100, card_type: "visa", paid_at: today.beginning_of_day) }

  it "executes a single SELECT for the whole month grid (prefetch mode)" do
    queries = []
    callback = ->(_n, _s, _f, _i, payload) do
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql] if payload[:sql].start_with?("SELECT") && payload[:sql].include?("\"payments\"")
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      visit "/admin/payments?year=2026&month=5"
    end

    puts "💾 payments SELECTs to render May 2026: #{queries.size}"
    queries.each_with_index { |q, i| puts "  [#{i}] #{q[0, 140]}" }

    # 1 prefetch query for the entire visible grid + 1 default-ordered AA query.
    expect(queries.size).to be <= 2
    expect(queries.any? { |q| q.include?("paid_at >=") && q.include?("paid_at <") }).to be(true)
  end
end
