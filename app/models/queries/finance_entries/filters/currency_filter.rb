# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      class CurrencyFilter < FinanceEntryFilter
        def type
          :list
        end

        def allowed_values
          FinanceCurrency.active.order(:code).pluck(:code, :code)
        end
      end
    end
  end
end
