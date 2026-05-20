# frozen_string_literal: true

ActiveAdmin.register Booking do
  config.paginate      = false
  config.batch_actions = false
  actions :index

  filter :room_number
  filter :guest_name_cont, label: "Guest name contains"

  # Each booking spans multiple days (check_in..check_out). A simple
  # `group_by: :check_in` would put it only on the check-in day. Using a
  # custom scope, the same row fans out across every active day in the grid.
  index as: :calendar, group_by_scope: :active_on do |date, bookings|
    ul do
      bookings.sort_by(&:room_number).each do |b|
        li do
          first_night = b.check_in == date
          last_night  = (b.check_out - 1.day) == date
          marker =
            if first_night && last_night then "•"
            elsif first_night             then "→"
            elsif last_night              then "←"
            else                               "·"
            end
          text_node "#{marker} ##{b.room_number} #{b.guest_name}"
        end
      end
    end
  end
end
