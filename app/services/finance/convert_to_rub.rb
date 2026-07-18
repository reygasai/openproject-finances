# frozen_string_literal: true

module Finance
  # Converts a finance entry amount to RUB using stored CBR rates.
  # Returns nil when no suitable rate exists (UI shows "rate unavailable").
  class ConvertToRub
    Result = Data.define(:amount_rub, :rate_date)

    def self.call(amount:, currency:, on:, lookup: nil)
      return lookup.convert(amount:, currency:, on:) if lookup

      new(amount:, currency:, on:).call
    end

    def initialize(amount:, currency:, on:)
      @amount = amount
      @currency = currency.to_s.upcase
      @on = on
    end

    def call
      return Result.new(amount_rub: @amount, rate_date: @on) if @currency == "RUB"

      rate = FinanceExchangeRate.for_conversion(currency_code: @currency, on: @on)
      return nil if rate.nil?

      Result.new(
        amount_rub: (@amount * rate.rate_per_unit).round(2),
        rate_date: rate.rate_date
      )
    end
  end
end
