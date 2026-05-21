# frozen_string_literal: true

# Load ActiveAdmin first so `ActiveAdmin::Views` exists by the time we
# register the view component. AA doesn't publish a load hook for itself
# (only `:active_admin_controller`), and `config.to_prepare` would fire
# too late for engines that require AA resources from an initializer.
# Sibling plugins (active_admin_sidebar, etc.) use the same pattern.
require "activeadmin"
require "activeadmin_calendar/version"

module ActiveadminCalendar
end

require "activeadmin_calendar/engine" if defined?(Rails)
require "activeadmin_calendar/index_as_calendar"
