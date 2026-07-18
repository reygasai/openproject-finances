# frozen_string_literal: true

module Finance
  module Cbr
    class FetchCurrenciesService
      def initialize(client: Client.new)
        @client = client
      end

      def call
        remote = @client.fetch_currencies
        # Empty catalog almost always means a parse/proxy failure — never mass-deactivate.
        if remote.blank?
          return ServiceResult.failure(message: I18n.t("finances.messages.cbr_empty_currency_catalog"))
        end

        remote_codes = remote.map { |c| c[:code] }

        FinanceCurrency.transaction do
          remote.each do |attrs|
            record = FinanceCurrency.find_or_initialize_by(code: attrs[:code])
            record.name = attrs[:name]
            record.active = true
            record.save!
          end

          # Keep RUB always active; deactivate codes missing from CBR catalog (except RUB).
          FinanceCurrency.where.not(code: remote_codes + ["RUB"]).update_all(active: false)
          FinanceCurrency.find_or_create_by!(code: "RUB") do |rub|
            rub.name = "Russian Ruble"
            rub.active = true
          end
          FinanceCurrency.where(code: "RUB").update_all(active: true)
        end

        ServiceResult.success(result: { count: remote_codes.size })
      rescue StandardError => e
        Rails.logger.error("[Finance::Cbr::FetchCurrenciesService] #{e.class}: #{e.message}")
        ServiceResult.failure(message: e.message)
      end
    end
  end
end
