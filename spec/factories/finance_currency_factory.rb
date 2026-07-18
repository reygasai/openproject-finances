# frozen_string_literal: true

FactoryBot.define do
  factory :finance_currency do
    sequence(:code) { |n| format("C%02d", n % 100) }
    name { "Test Currency" }
    active { true }

    trait :rub do
      code { "RUB" }
      name { "Russian Ruble" }
    end

    trait :usd do
      code { "USD" }
      name { "US Dollar" }
    end
  end
end
