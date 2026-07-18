# frozen_string_literal: true

class CreateFinanceEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :finance_entries do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.decimal :amount, null: false, precision: 15, scale: 2
      t.string :currency, null: false, default: "RUB", limit: 3
      t.date :entry_date, null: false
      t.text :description
      t.references :author, null: false, foreign_key: { to_table: :users }

      t.timestamps

      t.index %i[project_id entry_date]
      t.index %i[project_id currency]
    end
  end
end
