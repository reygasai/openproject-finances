# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Finances::AmountHelper, type: :helper do
  include described_class

  before do
    create(:finance_exchange_rate, currency_code: "USD", rate_date: Date.current, rate: 90, nominal: 1)
  end

  it "formats RUB without conversion suffix" do
    entry = build(:finance_entry, amount: BigDecimal("12.5"), currency: "RUB", entry_date: Date.current)
    expect(finance_amount_display(entry)).to eq("12.50 RUB")
  end

  it "appends converted RUB for foreign currency" do
    entry = build(:finance_entry, amount: BigDecimal("2"), currency: "USD", entry_date: Date.current)
    expect(finance_amount_display(entry)).to include("2.00 USD")
    expect(finance_amount_display(entry)).to include("180.00 RUB")
  end

  it "marks missing rates" do
    entry = build(:finance_entry, amount: BigDecimal("2"), currency: "EUR", entry_date: Date.current)
    expect(finance_amount_display(entry)).to include(I18n.t("finances.label_rate_unavailable"))
  end
end
