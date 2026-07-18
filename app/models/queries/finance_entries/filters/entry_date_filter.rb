# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      class EntryDateFilter < FinanceEntryFilter
        def type
          :date
        end
      end
    end
  end
end
