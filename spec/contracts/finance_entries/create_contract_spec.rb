# frozen_string_literal: true

require_relative "../../spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe FinanceEntries::CreateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project, enabled_module_names: %i[finances]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_finance_entries create_finance_entries]
           })
  end
  let(:entry) { build(:finance_entry, project:, author: user) }
  let(:contract) { described_class.new(entry, user) }

  describe "validation" do
    before do
      ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
      login_as(user)
    end

    it_behaves_like "contract is valid"

    context "without create permission" do
      let(:user) do
        create(:user, member_with_permissions: {
                 project => %i[view_finance_entries]
               })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "with inactive currency" do
      before { entry.currency = "ZZZ" }

      it_behaves_like "contract is invalid", currency: :inclusion
    end

    context "with non-member user participant" do
      let(:outsider) { create(:user) }

      before { entry.user_participants = [outsider] }

      it_behaves_like "contract is invalid", user_participants: :invalid
    end

    context "with a work package from another project" do
      let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking]) }
      let(:foreign_wp) { create(:work_package, project: other_project) }

      before do
        entry.requested_work_package_ids = [foreign_wp.id]
        entry.work_packages = []
      end

      it_behaves_like "contract is invalid", work_packages: :invalid
    end

    context "with a missing work package id" do
      before do
        entry.requested_work_package_ids = [0]
        entry.work_packages = []
      end

      it_behaves_like "contract is invalid", work_packages: :invalid
    end
  end
end
