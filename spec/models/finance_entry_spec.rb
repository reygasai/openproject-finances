# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe FinanceEntry do
  shared_let(:project) { create(:project, enabled_module_names: %i[finances work_package_tracking]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_finance_entries] }) }

  before do
    ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
    login_as(user)
  end

  describe "validations" do
    it "is valid with required attributes" do
      entry = build(:finance_entry, project:, author: user)
      expect(entry).to be_valid
    end

    it "rejects zero amount" do
      entry = build(:finance_entry, project:, author: user, amount: 0)
      expect(entry).not_to be_valid
      expect(entry.errors[:amount]).to be_present
    end
  end

  describe "#income? / #expense?" do
    it "detects income and expense by sign" do
      expect(build(:finance_entry, amount: 10)).to be_income
      expect(build(:finance_entry, :expense)).to be_expense
    end
  end

  describe ".visible" do
    let!(:visible_entry) { create(:finance_entry, project:, author: user) }
    let!(:other_project) { create(:project, enabled_module_names: %i[finances]) }
    let!(:hidden_entry) { create(:finance_entry, project: other_project, author: user) }

    it "returns only entries the user can view" do
      expect(described_class.visible(user)).to include(visible_entry)
      expect(described_class.visible(user)).not_to include(hidden_entry)
    end
  end
end
