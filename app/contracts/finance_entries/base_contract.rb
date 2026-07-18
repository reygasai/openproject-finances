# frozen_string_literal: true

module FinanceEntries
  class BaseContract < ::ModelContract
    def self.model
      FinanceEntry
    end

    attribute :project_id
    attribute :amount
    attribute :currency
    attribute :entry_date
    attribute :description
    attribute :author_id

    validate :validate_amount_not_zero
    validate :validate_currency_active
    validate :validate_user_participants_are_members
    validate :validate_work_packages_in_project

    private

    def validate_amount_not_zero
      return if model.amount.blank?
      return if model.amount != 0

      errors.add :amount, :other_than, count: 0
    end

    def validate_currency_active
      return if model.currency.blank?
      return if FinanceCurrency.active.exists?(code: model.currency)
      # Keep existing entries editable after CBR deactivates their currency.
      return if model.persisted? && !model.currency_changed? && FinanceCurrency.exists?(code: model.currency)

      errors.add :currency, :inclusion
    end

    def validate_user_participants_are_members
      return if model.user_participants.empty?
      return unless model.project

      member_ids = model.project.users.pluck(:id)
      invalid = model.user_participants.map(&:id) - member_ids
      return if invalid.empty?

      errors.add :user_participants, :invalid
    end

    def validate_work_packages_in_project
      return unless model.project

      requested = model.requested_work_package_ids
      if requested
        allowed_ids = model.project.work_packages.where(id: requested).pluck(:id)
        if (requested - allowed_ids).any?
          errors.add :work_packages, :invalid
        end
        return
      end

      return if model.work_packages.empty?

      outside = model.work_packages.reject { |wp| wp.project_id == model.project_id }
      return if outside.empty?

      errors.add :work_packages, :invalid
    end
  end
end
