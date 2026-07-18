# frozen_string_literal: true

class FinanceEntryUserParticipant < ApplicationRecord
  belongs_to :finance_entry
  belongs_to :user

  validates :finance_entry, :user, presence: true
  validates :user_id, uniqueness: { scope: :finance_entry_id }
end
