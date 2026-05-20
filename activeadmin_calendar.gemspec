# frozen_string_literal: true

require_relative "lib/activeadmin_calendar/version"

Gem::Specification.new do |spec|
  spec.name        = "activeadmin_calendar"
  spec.version     = ActiveadminCalendar::VERSION
  spec.authors     = ["Igor Fedoronchuk"]
  spec.email       = ["fedoronchuk@gmail.com"]

  spec.summary     = "Calendar index style for ActiveAdmin"
  spec.description = "Adds `index as: :calendar` — a month-grid index style that buckets " \
                     "resources by a date attribute or custom scope and yields each day cell."
  spec.homepage    = "https://github.com/activeadmin-plugins/activeadmin_calendar"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/releases"

  spec.files = Dir["lib/**/*", "app/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activeadmin", ">= 3.5", "< 5.0"
  spec.add_dependency "arbre", ">= 1.4", "< 3.0"
  spec.add_dependency "railties", ">= 7.0"
end
