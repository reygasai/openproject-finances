# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      class AuthorFilter < FinanceEntryFilter
        def type
          :list_optional
        end

        def allowed_values
          # Values supplied via principal autocompleter in UI; keep open.
          []
        end

        def where
          operator_strategy.sql_for_field(values, self.class.model.table_name, "author_id")
        end
      end
    end
  end
end
