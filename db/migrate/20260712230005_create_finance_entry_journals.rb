# frozen_string_literal: true

class CreateFinanceEntryJournals < ActiveRecord::Migration[8.0]
  def change
    create_table :finance_entry_journals do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.decimal :amount, precision: 15, scale: 2
      t.string :currency, limit: 3
      t.date :entry_date
      t.text :description
      t.bigint :author_id
      t.bigint :project_id
    end
  end
end
