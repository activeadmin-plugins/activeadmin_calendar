# frozen_string_literal: true

module ActiveAdmin
  module Views
    # = Index as a Calendar
    #
    # Render the index page as a month calendar grid. Resources are bucketed
    # into day cells by a configurable attribute (default: `updated_at`) or via
    # a custom scope.
    #
    #     index as: :calendar, group_by: :paid_at do |date, payments|
    #       ul { payments.each { |p| li p.amount } }
    #     end
    #
    # For pre-bucketed scopes (when the group-by column is not on the table or
    # needs custom SQL) pass `:group_by_scope`:
    #
    #     scope :on_date, ->(date) { where(paid_at: date.all_day) }
    #     index as: :calendar, group_by_scope: :on_date do |date, items|
    #       # ...
    #     end
    class IndexAsCalendar < ActiveAdmin::Component
      def self.index_name
        "calendar"
      end

      def build(page_presenter, collection)
        @page_presenter = page_presenter
        @collection = collection
        prefetch_month_records!
        build_calendar
      end

      def group_by
        @page_presenter[:group_by] || :updated_at
      end

      def group_by_scope
        @page_presenter[:group_by_scope]
      end

      private

      def build_calendar
        build_navigation
        build_table
      end

      def build_navigation
        prev_month = current_month.at_beginning_of_month - 1
        next_month = current_month.at_end_of_month + 1

        div id: "index_calendar_header" do
          h2 current_month.strftime("%B %Y")

          ul id: "index_calendar_nav" do
            li link_to("Today", params.to_unsafe_h.except(:year, :month)), class: "today"
            li link_to("Previous", params.to_unsafe_h.merge(year: prev_month.year, month: prev_month.month)), class: "prev"
            li link_to("Next", params.to_unsafe_h.merge(year: next_month.year, month: next_month.month)), class: "next"
          end
        end
      end

      def build_table
        table id: "index_calendar" do
          build_table_headers
          build_table_body
        end
      end

      def build_table_headers
        thead do
          tr do
            7.times do |i|
              th I18n.t("date.abbr_day_names").rotate[i].to_s.capitalize
            end
          end
        end
      end

      def build_table_body
        tbody do
          (grid_start_date..grid_end_date).to_a.in_groups_of(7).each { |week| build_week(week) }
        end
      end

      def build_week(dates)
        tr { dates.each { |d| build_day(d) } }
      end

      def build_day(date)
        active = date.month == current_month.month && date.year == current_month.year
        classes = [active ? "current_month" : "not_current_month"]
        classes << "today" if date == Time.zone.now.to_date

        td class: classes.join(" ") do
          div class: "day" do
            date.day == 1 ? date.strftime("%b #{date.day}") : date.day.to_s
          end
          scope = day_scope(date)
          instance_exec(date, scope, &@page_presenter.block) if @page_presenter.block
        end
      end

      # Pre-loads the entire visible month range in one SQL query and groups
      # the rows in Ruby by date. Called once in #build. Skipped when the user
      # opts into `group_by_scope:` — that mode keeps per-cell semantics since
      # we can't infer how a custom scope buckets rows.
      def prefetch_month_records!
        return if group_by_scope
        return unless @collection.respond_to?(:where)

        col = group_by.to_s
        records = @collection.where("#{col} >= ? AND #{col} < ?", grid_start_date, grid_end_date.tomorrow).to_a
        @prefetched_by_date = records.group_by do |r|
          val = r.public_send(group_by)
          val.respond_to?(:to_date) ? val.to_date : val
        end
        @prefetched_by_date.default = [].freeze
      end

      def day_scope(date)
        if group_by_scope
          @collection.public_send(group_by_scope, date)
        else
          @prefetched_by_date[date]
        end
      end

      def grid_start_date
        current_month.at_beginning_of_month.beginning_of_week
      end

      def grid_end_date
        current_month.at_end_of_month.end_of_week
      end

      def current_month
        @current_month ||= begin
          now = Time.zone.now
          year  = params[:year].presence&.to_i  || now.year
          month = params[:month].presence&.to_i || now.month
          Date.new(year, month, 1)
        rescue Date::Error, ArgumentError, TypeError
          now.to_date.beginning_of_month
        end
      end
    end
  end
end
