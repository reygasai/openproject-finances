# frozen_string_literal: true

FactoryBot.define do
  factory :finance_external_participant do
    project
    sequence(:name) { |n| "External Person #{n}" }
  end
end
