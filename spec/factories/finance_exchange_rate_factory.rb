# frozen_string_literal: true

FactoryBot.define do
  factory :finance_exchange_rate do
    currency_code { "USD" }
    rate_date { Date.current }
    rate { BigDecimal("90.5") }
    nominal { 1 }
  end
end
