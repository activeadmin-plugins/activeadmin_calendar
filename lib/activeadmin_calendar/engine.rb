# frozen_string_literal: true

require "rails/engine"

module ActiveadminCalendar
  class Engine < ::Rails::Engine
    config.to_prepare do
      require "activeadmin_calendar/index_as_calendar"
    end
  end
end
