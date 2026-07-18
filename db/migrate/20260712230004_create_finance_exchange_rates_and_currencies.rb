# frozen_string_literal: true

class CreateFinanceExchangeRatesAndCurrencies < ActiveRecord::Migration[8.0]
  def up
    create_table :finance_exchange_rates do |t|
      t.string :currency_code, null: false, limit: 3
      t.date :rate_date, null: false
      t.decimal :rate, null: false, precision: 18, scale: 6
      t.integer :nominal, null: false, default: 1

      t.timestamps

      t.index %i[currency_code rate_date],
              unique: true,
              name: "index_finance_exchange_rates_unique"
    end

    create_table :finance_currencies do |t|
      t.string :code, null: false, limit: 3
      t.string :name
      t.boolean :active, null: false, default: true

      t.timestamps

      t.index :code, unique: true
    end

    # RUB is not present in CBR foreign-currency catalog; seed always.
    execute <<~SQL.squish
      INSERT INTO finance_currencies (code, name, active, created_at, updated_at)
      VALUES ('RUB', 'Russian Ruble', TRUE, NOW(), NOW())
      ON CONFLICT (code) DO NOTHING
    SQL
  end

  def down
    drop_table :finance_currencies
    drop_table :finance_exchange_rates
  end
end
