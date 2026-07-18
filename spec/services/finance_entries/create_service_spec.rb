# frozen_string_literal: true

require_relative "../../spec_helper"
require "services/base_services/behaves_like_create_service"

RSpec.describe FinanceEntries::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:call_attributes) { { amount: 10, currency: "RUB", entry_date: Date.current } }
  end

  describe "integration" do
    shared_let(:project) { create(:project, enabled_module_names: %i[finances work_package_tracking]) }
    shared_let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_finance_entries create_finance_entries]
             })
    end
    shared_let(:member) do
      create(:user, member_with_permissions: {
               project => %i[view_finance_entries]
             })
    end

    before do
      ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
      login_as(user)
    end

    it "creates an entry with user and external participants" do
      result = described_class
                 .new(user:)
                 .call(
                   project:,
                   amount: BigDecimal("-25.5"),
                   currency: "RUB",
                   entry_date: Date.current,
                   description: "Taxi",
                   user_participant_ids: [member.id],
                   external_participant_names: ["ООО Ромашка"]
                 )

      expect(result).to be_success
      entry = result.result
      expect(entry).to be_persisted
      expect(entry.author).to eq(user)
      expect(entry.user_participants).to contain_exactly(member)
      expect(entry.external_participants.map(&:name)).to contain_exactly("ООО Ромашка")
    end
  end
end
