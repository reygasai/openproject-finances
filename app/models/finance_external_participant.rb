# frozen_string_literal: true

class FinanceExternalParticipant < ApplicationRecord
  belongs_to :project

  has_many :finance_entry_external_participants, dependent: :destroy
  has_many :finance_entries, through: :finance_entry_external_participants

  validates :project, :name, presence: true
  validates :name, uniqueness: { scope: :project_id, case_sensitive: false }

  before_validation :normalize_name

  def self.find_or_create_for_project!(project:, name:)
    normalized = name.to_s.strip
    raise ArgumentError, "name blank" if normalized.blank?

    existing = find_for_project(project:, name: normalized)
    return existing if existing

    create!(project:, name: normalized)
  rescue ActiveRecord::RecordNotUnique
    find_for_project(project:, name: normalized) || raise
  end

  def self.find_for_project(project:, name:)
    where(project:)
      .where("LOWER(name) = LOWER(?)", name)
      .first
  end

  private

  def normalize_name
    self.name = name.to_s.strip.presence
  end
end
