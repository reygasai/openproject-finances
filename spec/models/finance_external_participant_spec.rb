# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe FinanceExternalParticipant do
  shared_let(:project) { create(:project) }

  describe ".find_or_create_for_project!" do
    it "reuses an existing participant case-insensitively" do
      existing = described_class.create!(project:, name: "Acme")

      result = described_class.find_or_create_for_project!(project:, name: "acme")

      expect(result).to eq(existing)
      expect(described_class.where(project:).count).to eq(1)
    end

    it "creates when no case-insensitive match exists" do
      result = described_class.find_or_create_for_project!(project:, name: "New Vendor")

      expect(result).to be_persisted
      expect(result.name).to eq("New Vendor")
    end

    it "raises on blank name" do
      expect do
        described_class.find_or_create_for_project!(project:, name: "  ")
      end.to raise_error(ArgumentError)
    end
  end
end
