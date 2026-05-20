# frozen_string_literal: true

ActiveAdmin.register Payment do
  config.paginate      = false
  config.batch_actions = false
  actions :index

  filter :card_type, as: :select, collection: Payment::CARD_TYPES

  index as: :calendar, group_by: :paid_at do |date, payments|
    by_card = payments.group_by(&:card_type)
                      .transform_values { |ps| ps.sum(&:amount) }
    ul do
      by_card.each do |card_type, amount|
        li do
          text_node "#{card_type.upcase}: #{number_to_currency(amount)}"
        end
      end

      total = by_card.values.sum
      next if total.zero?

      li do
        strong "Total: #{number_to_currency(total)}"
      end
    end
  end
end
