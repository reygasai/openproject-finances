# frozen_string_literal: true

require_relative "../spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe FinanceEntries::UpdateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project, enabled_module_names: %i[finances]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_finance_entries edit_finance_entries]
           })
  end
  let(:entry) { create(:finance_entry, project:, author: user, currency: "USD") }
  let(:contract) { described_class.new(entry, user) }

  describe "validation" do
    before do
      ensure_finance_currency!(code: "USD", name: "US Dollar", active: true)
      login_as(user)
    end

    it_behaves_like "contract is valid"

    context "without edit permission" do
      let(:user) do
        create(:user, member_with_permissions: {
                 project => %i[view_finance_entries]
               })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when currency became inactive but is unchanged" do
      before do
        ensure_finance_currency!(code: "USD", name: "US Dollar", active: false)
        entry.description = "Updated note"
      end

      it_behaves_like "contract is valid"
    end

    context "when changing to an inactive currency" do
      before do
        ensure_finance_currency!(code: "EUR", name: "Euro", active: false)
        entry.currency = "EUR"
      end

      it_behaves_like "contract is invalid", currency: :inclusion
    end
  end
end
