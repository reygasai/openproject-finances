# frozen_string_literal: true

class CreateFinanceExternalParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :finance_external_participants do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.string :name, null: false

      t.timestamps
    end

    # Case-insensitive uniqueness within a project
    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          CREATE UNIQUE INDEX index_finance_external_participants_on_project_lower_name
          ON finance_external_participants (project_id, lower(name))
        SQL
      end
      dir.down do
        execute <<~SQL.squish
          DROP INDEX IF EXISTS index_finance_external_participants_on_project_lower_name
        SQL
      end
    end

    create_table :finance_entry_external_participants do |t|
      t.references :finance_entry, null: false, foreign_key: true, index: true
      t.references :finance_external_participant,
                   null: false,
                   foreign_key: true,
                   index: { name: "index_finance_entry_ext_participants_on_ext_id" }

      t.timestamps

      t.index %i[finance_entry_id finance_external_participant_id],
              unique: true,
              name: "index_finance_entry_ext_participants_unique"
    end
  end
end
