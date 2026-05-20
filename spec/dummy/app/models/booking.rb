# frozen_string_literal: true

class Booking < ApplicationRecord
  # A booking is "active" on every day between check-in and the night before
  # check-out (last night the guest stays). The calendar cell for each date in
  # that range should show the booking — a single record fans out across N days.
  scope :active_on, ->(date) {
    where("check_in <= ? AND check_out > ?", date, date)
  }

  def nights
    (check_out - check_in).to_i
  end

  def self.ransackable_attributes(_ = nil)
    %w[id guest_name room_number check_in check_out created_at updated_at]
  end

  def self.ransackable_associations(_ = nil)
    []
  end
end
