# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Finance entries", type: :request do
  shared_let(:project) { create(:project, enabled_module_names: %i[finances work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[
               view_finance_entries
               create_finance_entries
               edit_finance_entries
               delete_finance_entries
             ]
           })
  end

  before do
    ensure_finance_currency!(code: "RUB", name: "Russian Ruble")
    login_as(user)
  end

  describe "GET /projects/:project_id/finance_entries" do
    let!(:entry) { create(:finance_entry, project:, author: user, description: "Office rent") }

    it "renders the index" do
      get project_finance_entries_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Office rent")
      expect(response.body).to include(I18n.t("finances.label_summary"))
    end

    it "filters by entry type" do
      create(:finance_entry, :expense, project:, author: user, description: "Taxi")
      filters = [{ "entry_type" => { "operator" => "=", "values" => ["expense"] } }].to_json

      get project_finance_entries_path(project, filters:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxi")
      expect(response.body).not_to include("Office rent")
    end

    it "exports filtered entries as CSV" do
      create(:finance_entry, :expense, project:, author: user, description: "Taxi")
      filters = [{ "entry_type" => { "operator" => "=", "values" => ["expense"] } }].to_json

      get project_finance_entries_path(project, format: :csv, filters:)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include("Taxi")
      expect(response.body).not_to include("Office rent")
    end

    it "exports entries as XLS" do
      get project_finance_entries_path(project, format: :xls)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.ms-excel")
      expect(response.body.bytesize).to be_positive
      expect(response.headers["Content-Disposition"]).to include(".xls")
    end

    it "redirects out-of-range page to the last available page" do
      get project_finance_entries_path(project, page: 99)

      expect(response).to redirect_to(project_finance_entries_path(project))
    end

    it "orders by entry_date descending by default" do
      older = create(:finance_entry, project:, author: user, entry_date: Date.new(2026, 1, 1), description: "Older")
      newer = create(:finance_entry, project:, author: user, entry_date: Date.new(2026, 6, 1), description: "Newer")

      get project_finance_entries_path(project)

      expect(response.body.index("Newer")).to be < response.body.index("Older")
      expect(response.body.index("Newer")).to be < response.body.index("Office rent")
      expect(older.entry_date).to be < newer.entry_date
    end

    it "orders by entry_date ascending when requested" do
      create(:finance_entry, project:, author: user, entry_date: Date.new(2026, 1, 1), description: "Older")
      create(:finance_entry, project:, author: user, entry_date: Date.new(2026, 6, 1), description: "Newer")

      get project_finance_entries_path(project, sortBy: [["entry_date", "asc"]].to_json)

      expect(response).to have_http_status(:ok)
      expect(response.body.index("Older")).to be < response.body.index("Newer")
    end
  end

  describe "POST /projects/:project_id/finance_entries" do
    it "creates an entry" do
      expect do
        post project_finance_entries_path(project),
             params: {
               finance_entry: {
                 amount: "-12.5",
                 currency: "RUB",
                 entry_date: Date.current.to_s,
                 description: "Coffee",
                 external_participant_names_input: "Cafe"
               }
             }
      end.to change(FinanceEntry, :count).by(1)

      expect(response).to redirect_to(project_finance_entries_path(project))
      entry = FinanceEntry.last
      expect(entry.amount).to eq(BigDecimal("-12.5"))
      expect(entry.external_participants.map(&:name)).to contain_exactly("Cafe")
    end
  end

  describe "PATCH /finance_entries/:id" do
    let!(:member) do
      create(:user, member_with_permissions: {
               project => %i[view_finance_entries]
             })
    end
    let!(:entry) do
      create(:finance_entry, project:, author: user, user_participants: [member])
    end

    it "updates scalar fields without clearing omitted associations" do
      patch finance_entry_path(entry),
            params: {
              finance_entry: {
                amount: "50",
                currency: "RUB",
                entry_date: Date.current.to_s,
                description: "Updated"
              }
            }

      expect(response).to redirect_to(project_finance_entries_path(project))
      entry.reload
      expect(entry.description).to eq("Updated")
      expect(entry.user_participants).to contain_exactly(member)
    end

    it "clears participants when empty array is submitted" do
      patch finance_entry_path(entry),
            params: {
              finance_entry: {
                amount: entry.amount,
                currency: entry.currency,
                entry_date: entry.entry_date.to_s,
                description: entry.description,
                user_participant_ids: [""]
              }
            }

      expect(response).to redirect_to(project_finance_entries_path(project))
      expect(entry.reload.user_participants).to be_empty
    end
  end

  describe "GET /finance_entries/:id/history" do
    let!(:entry) { create(:finance_entry, project:, author: user) }

    it "opens history dialog" do
      get history_finance_entry_path(entry), as: :turbo_stream

      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /finance_entries/:id" do
    let!(:entry) { create(:finance_entry, project:, author: user) }

    it "deletes the entry" do
      expect do
        delete finance_entry_path(entry)
      end.to change(FinanceEntry, :count).by(-1)

      expect(response).to redirect_to(project_finance_entries_path(project))
    end
  end
end
