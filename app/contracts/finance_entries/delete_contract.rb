# frozen_string_literal: true

module FinanceEntries
  class DeleteContract < ::DeleteContract
    delete_permission :delete_finance_entries
  end
end
