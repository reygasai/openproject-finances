# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Finance::ExchangeRateLookup do
  it "converts using preloaded rates without per-entry queries" do
    ensure_finance_currency!(code: "USD", name: "US Dollar")
    create(:finance_exchange_rate, currency_code: "USD", rate_date: Date.current - 1, rate: 80, nominal: 1)
    create(:finance_exchange_rate, currency_code: "USD", rate_date: Date.current, rate: 100, nominal: 1)

    entries = [
      build(:finance_entry, amount: 2, currency: "USD", entry_date: Date.current),
      build(:finance_entry, amount: 3, currency: "USD", entry_date: Date.current - 1),
      build(:finance_entry, amount: 5, currency: "RUB", entry_date: Date.current)
    ]

    lookup = described_class.for_entries(entries)

    query_count = 0
    counter = lambda { |*| query_count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      expect(lookup.convert(amount: 2, currency: "USD", on: Date.current).amount_rub).to eq(BigDecimal("200"))
      expect(lookup.convert(amount: 3, currency: "USD", on: Date.current - 1).amount_rub).to eq(BigDecimal("240"))
      expect(lookup.convert(amount: 5, currency: "RUB", on: Date.current).amount_rub).to eq(BigDecimal("5"))
    end

    expect(query_count).to eq(0)
  end
end
