# frozen_string_literal: true

class CreateFinanceEntryUserParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :finance_entry_user_participants do |t|
      t.references :finance_entry, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps

      t.index %i[finance_entry_id user_id],
              unique: true,
              name: "index_finance_entry_user_participants_unique"
    end
  end
end
