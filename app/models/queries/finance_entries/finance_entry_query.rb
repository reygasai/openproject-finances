# frozen_string_literal: true

module Queries
  module FinanceEntries
    class FinanceEntryQuery
      include ::Queries::BaseQuery
      include ::Queries::UnpersistedQuery

      def self.model
        FinanceEntry
      end

      def default_scope
        FinanceEntry.visible(User.current)
      end
    end
  end
end
