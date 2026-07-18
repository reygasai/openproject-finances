# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe FinanceEntries::Totals do
  shared_let(:project) { create(:project, enabled_module_names: %i[finances]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_finance_entries] }) }

  before do
    ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
    ensure_finance_currency!(code: "USD", name: "US Dollar")
    create(:finance_exchange_rate, currency_code: "USD", rate_date: Date.current, rate: 100, nominal: 1)
    create(:finance_entry, project:, author: user, amount: 100, currency: "RUB")
    create(:finance_entry, project:, author: user, amount: 2, currency: "USD")
    create(:finance_entry, project:, author: user, amount: 5, currency: "EUR") # missing rate
  end

  it "sums converted RUB totals and counts missing rates" do
    result = described_class.new(FinanceEntry.where(project:)).call

    expect(result.entry_count).to eq(3)
    expect(result.total_rub).to eq(BigDecimal("300")) # 100 + 2*100
    expect(result.missing_rate_count).to eq(1)
    expect(result.by_currency["RUB"]).to eq(BigDecimal("100"))
    expect(result.by_currency["USD"]).to eq(BigDecimal("2"))
  end
end
