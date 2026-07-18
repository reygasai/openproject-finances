# frozen_string_literal: true

class CreateFinanceEntryWorkPackages < ActiveRecord::Migration[8.0]
  def change
    create_table :finance_entry_work_packages do |t|
      t.references :finance_entry, null: false, foreign_key: true, index: true
      t.references :work_package,
                   null: false,
                   foreign_key: { on_delete: :cascade },
                   index: true

      t.timestamps

      t.index %i[finance_entry_id work_package_id],
              unique: true,
              name: "index_finance_entry_work_packages_unique"
    end
  end
end
