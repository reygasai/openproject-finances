# frozen_string_literal: true

class FinanceEntryExternalParticipant < ApplicationRecord
  belongs_to :finance_entry
  belongs_to :finance_external_participant

  validates :finance_entry, :finance_external_participant, presence: true
  validates :finance_external_participant_id, uniqueness: { scope: :finance_entry_id }
end
