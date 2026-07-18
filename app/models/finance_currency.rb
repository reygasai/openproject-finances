# frozen_string_literal: true

class FinanceCurrency < ApplicationRecord
  validates :code, presence: true, length: { is: 3 }, uniqueness: true

  scope :active, -> { where(active: true) }

  def self.rub
    find_by!(code: "RUB")
  end
end
