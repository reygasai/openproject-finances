# frozen_string_literal: true

class AddAssociationSnapshotsToFinanceEntryJournals < ActiveRecord::Migration[8.0]
  def change
    change_table :finance_entry_journals, bulk: true do |t|
      t.text :user_participant_names
      t.text :external_participant_names
      t.text :work_package_subjects
    end
  end
end
