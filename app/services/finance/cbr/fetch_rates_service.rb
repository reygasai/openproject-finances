# frozen_string_literal: true

module Finance
  module Cbr
    class FetchRatesService
      def initialize(client: Client.new, date: Date.current)
        @client = client
        @date = date
      end

      def call
        payload = @client.fetch_daily(date: @date)
        upserted = 0

        FinanceExchangeRate.transaction do
          payload[:rates].each do |attrs|
            record = FinanceExchangeRate.find_or_initialize_by(
              currency_code: attrs[:currency_code],
              rate_date: attrs[:rate_date]
            )
            record.rate = attrs[:rate]
            record.nominal = attrs[:nominal]
            record.save!
            upserted += 1
          end
        end

        ServiceResult.success(result: { rate_date: payload[:rate_date], upserted: })
      rescue StandardError => e
        Rails.logger.error("[Finance::Cbr::FetchRatesService] #{e.class}: #{e.message}")
        ServiceResult.failure(message: e.message)
      end
    end
  end
end
