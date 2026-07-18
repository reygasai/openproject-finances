# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Queries::FinanceEntries::Filters::UserParticipantFilter do
  describe "#where" do
    it "returns no matches for empty equals values" do
      filter = described_class.create!(name: :user_participant_id, operator: "=", values: [])
      expect(filter.where).to eq("1=0")
    end

    it "returns all matches for empty exclusion values" do
      filter = described_class.create!(name: :user_participant_id, operator: "!", values: [""])
      expect(filter.where).to eq("1=1")
    end
  end
end
