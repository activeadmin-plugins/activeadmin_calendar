# frozen_string_literal: true

class Payment < ApplicationRecord
  CARD_TYPES = %w[visa mastercard amex].freeze

  validates :card_type, inclusion: { in: CARD_TYPES }

  scope :paid_on, ->(date) { where(paid_at: date.beginning_of_day..date.end_of_day) }

  def self.ransackable_attributes(_ = nil)
    %w[id amount card_type paid_at created_at updated_at]
  end

  def self.ransackable_associations(_ = nil)
    []
  end
end
