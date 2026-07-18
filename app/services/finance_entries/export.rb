# frozen_string_literal: true

require "csv"

module FinanceEntries
  # Builds CSV / Excel exports for the full filtered entry scope (not one page).
  class Export
    def initialize(entries:, project:)
      @entries = Array(entries)
      @project = project
      @lookup = Finance::ExchangeRateLookup.for_entries(@entries)
    end

    def to_csv
      CSV.generate(col_sep: I18n.t(:general_csv_separator)) do |csv|
        csv << headers.map { |value| sanitize_cell(value) }
        @entries.each do |entry|
          csv << row_values(entry).map { |value| sanitize_cell(value) }
        end
      end
    end

    def to_xls
      spreadsheet = OpenProject::XlsExport::SpreadsheetBuilder.new(
        I18n.t("finances.label_finance_entries")
      )
      # idx 0 required: default add_row skips row 0 and leaves a nil row that
      # breaks SpreadsheetBuilder#xls width calculation.
      spreadsheet.add_headers(headers, 0)
      @entries.each do |entry|
        spreadsheet.add_row(row_values(entry, for_xls: true))
      end
      spreadsheet.xls
    end

    def filename(extension)
      "finance-entries-#{@project.identifier}-#{Date.current}.#{extension}"
    end

    private

    def headers
      [
        "#",
        FinanceEntry.human_attribute_name(:entry_date),
        FinanceEntry.human_attribute_name(:amount),
        FinanceEntry.human_attribute_name(:currency),
        I18n.t("finances.label_amount_rub"),
        I18n.t("finances.label_rate_date"),
        FinanceEntry.human_attribute_name(:description),
        I18n.t("finances.label_participants"),
        FinanceEntry.human_attribute_name(:work_packages),
        FinanceEntry.human_attribute_name(:author)
      ]
    end

    def row_values(entry, for_xls: false)
      conversion = @lookup.convert(
        amount: entry.amount,
        currency: entry.currency,
        on: entry.entry_date
      )

      description = sanitize_cell(entry.description.to_s)
      participants = sanitize_cell(participants_text(entry))
      work_packages = sanitize_cell(work_packages_text(entry))
      author = sanitize_cell(entry.author&.name.to_s)
      currency = sanitize_cell(entry.currency.to_s)

      [
        entry.id,
        for_xls ? entry.entry_date : format_date(entry.entry_date),
        for_xls ? entry.amount.to_f : format("%.2f", entry.amount),
        currency,
        conversion ? (for_xls ? conversion.amount_rub.to_f : format("%.2f", conversion.amount_rub)) : "",
        conversion ? (for_xls ? conversion.rate_date : format_date(conversion.rate_date)) : "",
        description,
        participants,
        work_packages,
        author
      ]
    end

    def participants_text(entry)
      [
        *entry.user_participants.map(&:name),
        *entry.external_participants.map(&:name)
      ].join(", ")
    end

    def work_packages_text(entry)
      entry.work_packages.map { |wp| "#{wp.subject} (##{wp.id})" }.join(", ")
    end

    def format_date(date)
      return "" if date.blank?

      I18n.l(date)
    end

    def sanitize_cell(value)
      Exports::Concerns::CSVFormulaSanitization.sanitize(value)
    end
  end
end
