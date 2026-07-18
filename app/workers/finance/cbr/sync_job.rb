# frozen_string_literal: true

module Finance
  module Cbr
    # Upserts CBR daily rates for the current calendar date (same date row, no duplicates).
    class SyncJob < ApplicationJob
      queue_as :default

      discard_on ActiveJob::DeserializationError

      def perform(date = Date.current)
        currencies = FetchCurrenciesService.new.call
        rates = FetchRatesService.new(date: date).call

        unless currencies.success? && rates.success?
          raise "CBR sync failed: currencies=#{currencies.message} rates=#{rates.message}"
        end

        Rails.logger.info(
          "[Finance::Cbr::SyncJob] synced currencies=#{currencies.result[:count]} " \
          "rates=#{rates.result[:upserted]} for #{rates.result[:rate_date]}"
        )
      end
    end
  end
end
