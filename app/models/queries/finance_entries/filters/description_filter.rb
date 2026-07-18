# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      class DescriptionFilter < FinanceEntryFilter
        def type
          :string
        end
      end
    end
  end
end
