# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      class FinanceEntryFilter < ::Queries::Filters::Base
        self.model = FinanceEntry

        def human_name
          FinanceEntry.human_attribute_name(name)
        end
      end
    end
  end
end
