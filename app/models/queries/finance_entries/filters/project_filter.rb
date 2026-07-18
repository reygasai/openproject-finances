# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      class ProjectFilter < FinanceEntryFilter
        include ::Queries::Filters::Shared::ProjectFilter::Optional
      end
    end
  end
end
