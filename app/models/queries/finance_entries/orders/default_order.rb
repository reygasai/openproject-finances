# frozen_string_literal: true

module Queries
  module FinanceEntries
    module Orders
      class DefaultOrder < ::Queries::Orders::Base
        self.model = FinanceEntry

        def self.key
          /\A(id|amount|entry_date|currency|created_at|updated_at)\z/
        end
      end
    end
  end
end
