# frozen_string_literal: true

require "rails/engine"

module ActiveadminCalendar
  # Empty engine — kept so Propshaft / Tailwind can discover this gem's
  # `app/assets/stylesheets` directory on AA 4. The view component
  # itself is required eagerly from `lib/activeadmin_calendar.rb` so it
  # is available before AA resources are loaded.
  class Engine < ::Rails::Engine
  end
end
