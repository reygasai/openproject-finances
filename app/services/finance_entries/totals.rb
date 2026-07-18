# frozen_string_literal: true

module FinanceEntries
  class Totals
    Result = Data.define(:total_rub, :by_currency, :missing_rate_count, :entry_count)

    def initialize(entries)
      @entries = entries
    end

    def call
      loaded = @entries.is_a?(Array) ? @entries : @entries.to_a
      lookup = Finance::ExchangeRateLookup.for_entries(loaded)

      total_rub = 0.to_d
      by_currency = Hash.new(0.to_d)
      missing = 0

      loaded.each do |entry|
        by_currency[entry.currency] += entry.amount

        conversion = lookup.convert(
          amount: entry.amount,
          currency: entry.currency,
          on: entry.entry_date
        )

        if conversion
          total_rub += conversion.amount_rub
        else
          missing += 1
        end
      end

      Result.new(
        total_rub:,
        by_currency: by_currency.sort.to_h,
        missing_rate_count: missing,
        entry_count: loaded.size
      )
    end
  end
end
