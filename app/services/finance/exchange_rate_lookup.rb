# frozen_string_literal: true

module Finance
  # Preloads exchange rates for a set of entries and converts without N+1 queries.
  class ExchangeRateLookup
    def self.for_entries(entries)
      new(entries)
    end

    def initialize(entries)
      @entries = Array(entries)
      @rate_cache = {}
      preload!
    end

    def convert(amount:, currency:, on:)
      currency = currency.to_s.upcase
      return ConvertToRub::Result.new(amount_rub: amount, rate_date: on) if currency == "RUB"

      rate = rate_for(currency, on)
      return nil if rate.nil?

      ConvertToRub::Result.new(
        amount_rub: (amount * rate.rate_per_unit).round(2),
        rate_date: rate.rate_date
      )
    end

    private

    def rate_for(currency, on)
      key = [currency, on]
      return @rate_cache[key] if @rate_cache.key?(key)

      @rate_cache[key] = @rates_by_currency[currency]&.find { |rate| rate.rate_date <= on }
    end

    def preload!
      @rates_by_currency = {}
      return if @entries.empty?

      currencies = @entries.map { |entry| entry.currency.to_s.upcase }.uniq - ["RUB"]
      return if currencies.empty?

      max_date = @entries.map(&:entry_date).compact.max
      return if max_date.nil?

      FinanceExchangeRate
        .where(currency_code: currencies)
        .where(rate_date: ..max_date)
        .order(:currency_code, rate_date: :desc)
        .group_by(&:currency_code)
        .each { |code, rates| @rates_by_currency[code] = rates }
    end
  end
end
