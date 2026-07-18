# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      # income => amount > 0, expense => amount < 0
      class EntryTypeFilter < FinanceEntryFilter
        def self.key
          :entry_type
        end

        def type
          :list
        end

        def human_name
          I18n.t("finances.label_entry_type")
        end

        def allowed_values
          [
            [I18n.t("finances.label_income"), "income"],
            [I18n.t("finances.label_expense"), "expense"]
          ]
        end

        def where
          case values.first
          when "income"
            "#{FinanceEntry.table_name}.amount > 0"
          when "expense"
            "#{FinanceEntry.table_name}.amount < 0"
          else
            "1=0"
          end
        end
      end
    end
  end
end
