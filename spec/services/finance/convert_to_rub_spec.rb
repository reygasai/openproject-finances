# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Finance::ConvertToRub do
  shared_let(:usd_rate) do
    create(:finance_exchange_rate, currency_code: "USD", rate_date: Date.new(2026, 7, 10), rate: 90, nominal: 1)
  end

  it "returns amount as-is for RUB" do
    result = described_class.call(amount: BigDecimal("100"), currency: "RUB", on: Date.current)

    expect(result.amount_rub).to eq(BigDecimal("100"))
    expect(result.rate_date).to eq(Date.current)
  end

  it "converts using rate on or before the given date" do
    result = described_class.call(amount: BigDecimal("2"), currency: "USD", on: Date.new(2026, 7, 12))

    expect(result.amount_rub).to eq(BigDecimal("180"))
    expect(result.rate_date).to eq(Date.new(2026, 7, 10))
  end

  it "returns nil when no rate exists" do
    result = described_class.call(amount: BigDecimal("2"), currency: "EUR", on: Date.new(2026, 7, 12))

    expect(result).to be_nil
  end

  it "respects nominal" do
    create(:finance_exchange_rate, currency_code: "JPY", rate_date: Date.new(2026, 7, 10), rate: 60, nominal: 100)

    result = described_class.call(amount: BigDecimal("100"), currency: "JPY", on: Date.new(2026, 7, 10))

    expect(result.amount_rub).to eq(BigDecimal("60"))
  end
end
