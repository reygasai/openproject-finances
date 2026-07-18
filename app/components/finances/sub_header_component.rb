# frozen_string_literal: true

module Finances
  class SubHeaderComponent < ApplicationComponent
    include OpTurbo::Streamable
    include ApplicationHelper

    def initialize(query:, project:, params: {})
      super
      @query = query
      @project = project
      @params = params
    end

    def filter_input_value
      @query.find_active_filter(:description)&.values&.first
    end

    def sub_header_data_attributes
      {
        controller: "filter--filters-form",
        "filter--filters-form-perform-turbo-requests-value": true,
        "filter--filters-form-output-format-value": "json",
        "filter--filters-form-clear-button-id-value": clear_button_id,
        "filter--filters-form-display-filters-value": filters_expanded?
      }
    end

    def filter_input_data_attributes
      {
        "filter-name": "description",
        "filter-type": "string",
        "filter-operator": "~",
        "filter--filters-form-target": "simpleFilter filterValueContainer simpleValue"
      }
    end

    def clear_button_id
      "finance-entries-filters-form-clear-button"
    end

    def filters_expanded?
      @params[:filters].present?
    end

    def can_create?
      User.current.allowed_in_project?(:create_finance_entries, @project)
    end

    def entry_date_sort_direction
      order = @query.orders.find { |item| item.attribute.to_s == "entry_date" }
      order&.direction || :desc
    end

    def sort_newest_first?
      entry_date_sort_direction != :asc
    end

    def sort_path(direction)
      helpers.project_finance_entries_path(
        @project,
        filters: @params[:filters],
        sortBy: [["entry_date", direction.to_s]].to_json
      )
    end

    def export_path(format:)
      helpers.project_finance_entries_path(
        @project,
        format:,
        filters: @params[:filters],
        sortBy: @params[:sortBy].presence || [["entry_date", entry_date_sort_direction.to_s]].to_json
      )
    end
  end
end
