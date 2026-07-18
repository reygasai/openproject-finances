# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Finance::Cbr::FetchCurrenciesService do
  subject(:service) { described_class.new(client:) }

  let(:client) { instance_double(Finance::Cbr::Client) }

  before do
    ensure_finance_currency!(code: "RUB", name: "Russian Ruble", active: true)
    ensure_finance_currency!(code: "USD", name: "US Dollar", active: true)
    ensure_finance_currency!(code: "EUR", name: "Euro", active: true)
  end

  it "does not deactivate currencies when the remote catalog is empty" do
    allow(client).to receive(:fetch_currencies).and_return([])

    result = service.call

    expect(result).to be_failure
    expect(result.message).to eq(I18n.t("finances.messages.cbr_empty_currency_catalog"))
    expect(FinanceCurrency.find_by(code: "USD").active).to be(true)
    expect(FinanceCurrency.find_by(code: "EUR").active).to be(true)
  end

  it "upserts remote currencies and deactivates missing ones" do
    allow(client).to receive(:fetch_currencies).and_return(
      [{ code: "USD", name: "US Dollar" }]
    )

    result = service.call

    expect(result).to be_success
    expect(FinanceCurrency.find_by(code: "USD").active).to be(true)
    expect(FinanceCurrency.find_by(code: "EUR").active).to be(false)
    expect(FinanceCurrency.find_by(code: "RUB").active).to be(true)
  end
end
