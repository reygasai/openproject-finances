# frozen_string_literal: true

class FinanceEntryWorkPackage < ApplicationRecord
  belongs_to :finance_entry
  belongs_to :work_package

  validates :finance_entry, :work_package, presence: true
  validates :work_package_id, uniqueness: { scope: :finance_entry_id }
end
