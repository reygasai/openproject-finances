# frozen_string_literal: true

FactoryBot.define do
  factory :finance_entry do
    project
    author factory: :user
    amount { BigDecimal("100.00") }
    currency { "RUB" }
    entry_date { Date.current }
    description { "Test finance entry" }

    trait :expense do
      amount { BigDecimal("-50.00") }
    end

    trait :usd do
      currency { "USD" }
      amount { BigDecimal("10.00") }
    end
  end
end
