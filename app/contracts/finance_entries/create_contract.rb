# frozen_string_literal: true

module FinanceEntries
  class CreateContract < BaseContract
    validate :user_allowed_to_create

    private

    def user_allowed_to_create
      return if model.project && user.allowed_in_project?(:create_finance_entries, model.project)

      errors.add :base, :error_unauthorized
    end
  end
end
