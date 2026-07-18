# frozen_string_literal: true

class FinanceExchangeRate < ApplicationRecord
  validates :currency_code, :rate_date, :rate, :nominal, presence: true
  validates :currency_code, length: { is: 3 }
  validates :nominal, numericality: { only_integer: true, greater_than: 0 }
  validates :rate, numericality: { greater_than: 0 }
  validates :currency_code, uniqueness: { scope: :rate_date }

  def self.for_conversion(currency_code:, on:)
    where(currency_code: currency_code.to_s.upcase)
      .where(rate_date: ..on)
      .order(rate_date: :desc)
      .first
  end

  def rate_per_unit
    rate / nominal
  end
end
