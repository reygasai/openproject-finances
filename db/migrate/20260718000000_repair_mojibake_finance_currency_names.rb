# frozen_string_literal: true

class RepairMojibakeFinanceCurrencyNames < ActiveRecord::Migration[8.0]
  class Currency < ActiveRecord::Base
    self.table_name = "finance_currencies"
  end

  def up
    Currency.find_each do |currency|
      repaired = repair_mojibake(currency.name.to_s)
      currency.update_columns(name: repaired) if repaired != currency.name
    end
  end

  def down
    # The original values were corrupted and must not be restored.
  end

  private

  def repair_mojibake(value)
    score = mojibake_score(value)
    return value if score.zero?

    repaired = value.encode("windows-1251").force_encoding(Encoding::UTF_8)
    return value unless repaired.valid_encoding? && mojibake_score(repaired) < score

    repaired
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    value
  end

  def mojibake_score(value)
    value.scan(/[РС][^\x00-\x7F]/).size
  end
end
