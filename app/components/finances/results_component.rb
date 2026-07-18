# frozen_string_literal: true

module Finances
  class ResultsComponent < ApplicationComponent
    include OpTurbo::Streamable

    def initialize(entries:, totals:, project:)
      super
      @entries = entries
      @totals = totals
      @project = project
      @rate_lookup = Finance::ExchangeRateLookup.for_entries(Array(entries))
    end

    def call
      component_wrapper do
        concat render(Finances::SummaryComponent.new(totals: @totals))
        concat tag.div(class: "mt-3") {
          render(
            Finances::TableComponent.new(
              rows: @entries,
              current_project: @project,
              rate_lookup: @rate_lookup
            )
          )
        }
      end
    end
  end
end
