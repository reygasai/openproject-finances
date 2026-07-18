# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Finance::Cbr::FetchRatesService do
  let(:client) { instance_double(Finance::Cbr::Client) }
  let(:date) { Date.new(2026, 7, 11) }

  before do
    allow(client).to receive(:fetch_daily).with(date:).and_return(
      rate_date: date,
      rates: [
        { currency_code: "USD", rate_date: date, rate: BigDecimal("90.5"), nominal: 1 }
      ]
    )
  end

  it "upserts rates for the date" do
    result = described_class.new(client:, date:).call

    expect(result).to be_success
    expect(result.result[:upserted]).to eq(1)

    rate = FinanceExchangeRate.find_by!(currency_code: "USD", rate_date: date)
    expect(rate.rate).to eq(BigDecimal("90.5"))

    # second call updates same row
    allow(client).to receive(:fetch_daily).with(date:).and_return(
      rate_date: date,
      rates: [
        { currency_code: "USD", rate_date: date, rate: BigDecimal("91.0"), nominal: 1 }
      ]
    )
    described_class.new(client:, date:).call
    expect(FinanceExchangeRate.where(currency_code: "USD", rate_date: date).count).to eq(1)
    expect(rate.reload.rate).to eq(BigDecimal("91.0"))
  end
end
