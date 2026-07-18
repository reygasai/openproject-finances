# frozen_string_literal: true

require_relative "../../spec_helper"
require "services/base_services/behaves_like_update_service"

RSpec.describe FinanceEntries::UpdateService, type: :model do
  it_behaves_like "BaseServices update service"

  describe "association updates" do
    shared_let(:project) { create(:project, enabled_module_names: %i[finances work_package_tracking]) }
    shared_let(:user) do
      create(:user, member_with_permissions: {
               project => %i[view_finance_entries edit_finance_entries]
             })
    end
    shared_let(:member) do
      create(:user, member_with_permissions: {
               project => %i[view_finance_entries]
             })
    end
    shared_let(:work_package) { create(:work_package, project:) }

    let!(:entry) do
      create(
        :finance_entry,
        project:,
        author: user,
        user_participants: [member],
        work_packages: [work_package]
      ).tap do |created|
        created.external_participants << create(:finance_external_participant, project:, name: "Cafe")
      end
    end

    before do
      ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
      login_as(user)
    end

    it "does not clear associations when association params are omitted" do
      result = described_class
                 .new(user:, model: entry)
                 .call(description: "Only description")

      expect(result).to be_success
      entry.reload
      expect(entry.description).to eq("Only description")
      expect(entry.user_participants).to contain_exactly(member)
      expect(entry.work_packages).to contain_exactly(work_package)
      expect(entry.external_participants.map(&:name)).to contain_exactly("Cafe")
    end

    it "clears associations when empty arrays are provided" do
      result = described_class
                 .new(user:, model: entry)
                 .call(
                   user_participant_ids: [],
                   work_package_ids: [],
                   external_participant_names: []
                 )

      expect(result).to be_success
      entry.reload
      expect(entry.user_participants).to be_empty
      expect(entry.work_packages).to be_empty
      expect(entry.external_participants).to be_empty
    end

    it "rejects out-of-project work package ids without clearing existing links" do
      foreign_wp = create(:work_package, project: create(:project, enabled_module_names: %i[work_package_tracking]))

      result = described_class
                 .new(user:, model: entry)
                 .call(work_package_ids: [foreign_wp.id])

      expect(result).to be_failure
      entry.reload
      expect(entry.work_packages).to contain_exactly(work_package)
    end
  end
end
