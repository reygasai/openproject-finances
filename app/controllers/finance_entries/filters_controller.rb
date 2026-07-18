# frozen_string_literal: true

class FinanceEntries::FiltersController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  def show
    query = ParamsToQueryService
              .new(FinanceEntry, User.current, query_class: Queries::FinanceEntries::FinanceEntryQuery)
              .call(params)
    query.where("project_id", "=", [@project.id.to_s])

    render Finances::FiltersComponent.new(query:, project: @project), layout: false
  end
end
