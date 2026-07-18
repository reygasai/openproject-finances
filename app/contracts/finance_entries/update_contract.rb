# frozen_string_literal: true

module FinanceEntries
  class UpdateContract < BaseContract
    validate :user_allowed_to_edit

    private

    def user_allowed_to_edit
      return if model.project && user.allowed_in_project?(:edit_finance_entries, model.project)

      errors.add :base, :error_unauthorized
    end
  end
end
