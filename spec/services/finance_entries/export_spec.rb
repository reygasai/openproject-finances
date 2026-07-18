# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe FinanceEntries::Export do
  shared_let(:project) { create(:project, enabled_module_names: %i[finances]) }
  shared_let(:author) { create(:user) }

  before do
    ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
  end

  subject(:export) { described_class.new(entries:, project:) }

  let!(:entry) do
    create(
      :finance_entry,
      project:,
      author:,
      amount: BigDecimal("150.50"),
      currency: "RUB",
      description: "Office rent",
      entry_date: Date.new(2026, 7, 1)
    )
  end
  let(:entries) { [entry] }

  describe "#to_csv" do
    it "includes headers and entry values" do
      csv = export.to_csv

      expect(csv).to include(FinanceEntry.human_attribute_name(:amount))
      expect(csv).to include("Office rent")
      expect(csv).to include("150.50")
      expect(csv).to include("RUB")
    end

    it "sanitizes formula-like description cells" do
      allow(Setting).to receive(:csv_escape_formulas?).and_return(true)
      entry.update!(description: "=CMD(\"calc\")")

      expect(export.to_csv).to include("'=CMD(\"calc\")")
    end
  end

  describe "#to_xls" do
    it "returns binary spreadsheet content" do
      expect(export.to_xls.bytesize).to be_positive
    end

    it "sanitizes formula-like description cells" do
      allow(Setting).to receive(:csv_escape_formulas?).and_return(true)
      entry.update!(description: "=1+1")

      xls = export.to_xls
      book = Spreadsheet.open(StringIO.new(xls))
      row = book.worksheet(0).rows.find { |r| r && r[0] == entry.id }

      expect(row[6]).to eq("'=1+1")
    end
  end

  describe "#filename" do
    it "uses the project identifier and extension" do
      expect(export.filename("csv")).to eq(
        "finance-entries-#{project.identifier}-#{Date.current}.csv"
      )
    end
  end
end
