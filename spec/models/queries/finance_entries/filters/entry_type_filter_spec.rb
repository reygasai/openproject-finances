# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Queries::FinanceEntries::Filters::EntryTypeFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :entry_type }
    let(:human_name) { I18n.t("finances.label_entry_type") }
  end

  describe "#where" do
    shared_let(:project) { create(:project, enabled_module_names: %i[finances]) }
    shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_finance_entries] }) }
    let!(:income) { create(:finance_entry, project:, author: user, amount: 100) }
    let!(:expense) { create(:finance_entry, :expense, project:, author: user) }

    before do
      ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
      login_as(user)
    end

    it "filters incomes" do
      filter = described_class.create!(name: :entry_type, operator: "=", values: ["income"])
      expect(FinanceEntry.where(filter.where)).to contain_exactly(income)
    end

    it "filters expenses" do
      filter = described_class.create!(name: :entry_type, operator: "=", values: ["expense"])
      expect(FinanceEntry.where(filter.where)).to contain_exactly(expense)
    end
  end
end
