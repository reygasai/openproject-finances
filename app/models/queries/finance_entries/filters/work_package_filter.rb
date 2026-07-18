# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Filters
      class WorkPackageFilter < FinanceEntryFilter
        def self.key
          :work_package_id
        end

        def type
          :list_optional
        end

        def type_strategy
          @type_strategy ||= ::Queries::Filters::Strategies::IntegerListOptional.new(self)
        end

        def allowed_values
          []
        end

        def where
          case operator
          when "="
            return "1=0" if integer_values.empty?

            OpenProject::SqlSanitization.sanitize(<<~SQL.squish, integer_values)
              EXISTS (
                SELECT 1 FROM finance_entry_work_packages
                WHERE finance_entry_work_packages.finance_entry_id = finance_entries.id
                  AND finance_entry_work_packages.work_package_id IN (?)
              )
            SQL
          when "!"
            return "1=1" if integer_values.empty?

            OpenProject::SqlSanitization.sanitize(<<~SQL.squish, integer_values)
              NOT EXISTS (
                SELECT 1 FROM finance_entry_work_packages
                WHERE finance_entry_work_packages.finance_entry_id = finance_entries.id
                  AND finance_entry_work_packages.work_package_id IN (?)
              )
            SQL
          when "*"
            <<~SQL.squish
              EXISTS (
                SELECT 1 FROM finance_entry_work_packages
                WHERE finance_entry_work_packages.finance_entry_id = finance_entries.id
              )
            SQL
          when "!*"
            <<~SQL.squish
              NOT EXISTS (
                SELECT 1 FROM finance_entry_work_packages
                WHERE finance_entry_work_packages.finance_entry_id = finance_entries.id
              )
            SQL
          end
        end

        private

        def integer_values
          Array(values).filter_map { |value| Integer(value, exception: false) }
        end
      end
    end
  end
end
