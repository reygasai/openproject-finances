# frozen_string_literal: true

module Finances
  module SpecHelpers
    def ensure_finance_currency!(code:, name: code, active: true)
      FinanceCurrency.find_or_create_by!(code:) do |currency|
        currency.name = name
        currency.active = active
      end.tap do |currency|
        currency.update!(name:, active:)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Finances::SpecHelpers
end
