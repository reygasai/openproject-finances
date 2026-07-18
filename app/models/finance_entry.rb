# frozen_string_literal: true

class FinanceEntry < ApplicationRecord
  belongs_to :project
  belongs_to :author, class_name: "User"

  has_many :finance_entry_user_participants, dependent: :destroy
  has_many :user_participants, through: :finance_entry_user_participants, source: :user

  has_many :finance_entry_external_participants, dependent: :destroy
  has_many :external_participants,
           through: :finance_entry_external_participants,
           source: :finance_external_participant

  has_many :finance_entry_work_packages, dependent: :destroy
  has_many :work_packages, through: :finance_entry_work_packages

  # Set by SetAttributesService when work_package_ids are explicitly submitted,
  # so the contract can reject missing/out-of-project IDs that were silently dropped.
  attr_accessor :requested_work_package_ids

  # Association snapshots are computed via data_sql so M2M changes are journalized
  # without denormalized columns on finance_entries itself.
  acts_as_journalized data_sql: ->(*) { journal_association_data_sql }

  register_journal_formatted_fields "amount", formatter_key: :decimal
  register_journal_formatted_fields "currency", "description", "entry_date",
                                    "user_participant_names", "external_participant_names",
                                    "work_package_subjects",
                                    formatter_key: :plaintext
  register_journal_formatted_fields "author_id", "project_id", formatter_key: :named_association

  validates :amount, :currency, :entry_date, :project, :author, presence: true
  validates :amount, numericality: { other_than: 0 }
  validates :currency, length: { is: 3 }

  scope :visible, lambda { |user = User.current|
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(user, :view_finance_entries))
  }

  def self.journal_association_data_sql
    <<~SQL.squish
      LEFT JOIN LATERAL (
        SELECT string_agg(
                 TRIM(CONCAT(users.firstname, ' ', users.lastname)),
                 ', ' ORDER BY users.lastname, users.firstname, users.id
               ) AS user_participant_names
        FROM finance_entry_user_participants
        INNER JOIN users ON users.id = finance_entry_user_participants.user_id
        WHERE finance_entry_user_participants.finance_entry_id = finance_entries.id
      ) finance_user_participants_agg ON TRUE
      LEFT JOIN LATERAL (
        SELECT string_agg(
                 finance_external_participants.name,
                 ', ' ORDER BY finance_external_participants.name, finance_external_participants.id
               ) AS external_participant_names
        FROM finance_entry_external_participants
        INNER JOIN finance_external_participants
          ON finance_external_participants.id = finance_entry_external_participants.finance_external_participant_id
        WHERE finance_entry_external_participants.finance_entry_id = finance_entries.id
      ) finance_external_participants_agg ON TRUE
      LEFT JOIN LATERAL (
        SELECT string_agg(
                 CONCAT(work_packages.subject, ' (#', work_packages.id, ')'),
                 ', ' ORDER BY work_packages.id
               ) AS work_package_subjects
        FROM finance_entry_work_packages
        INNER JOIN work_packages ON work_packages.id = finance_entry_work_packages.work_package_id
        WHERE finance_entry_work_packages.finance_entry_id = finance_entries.id
      ) finance_work_packages_agg ON TRUE
    SQL
  end

  def income?
    amount.positive?
  end

  def expense?
    amount.negative?
  end
end
