# frozen_string_literal: true

require "open_project/plugins"

module OpenProject
  module Finances
    class Engine < ::Rails::Engine
      engine_name :openproject_finances

      include OpenProject::Plugins::ActsAsOpEngine

      register "openproject-finances",
               author_url: "https://github.com/reygasai/openproject-finances",
               requires_openproject: ">= 16.0.0" do
        project_module :finances do
          permission :view_finance_entries,
                     {
                       finance_entries: %i[index history],
                       "finance_entries/filters": %i[show]
                     },
                     permissible_on: :project
          permission :create_finance_entries,
                     { finance_entries: %i[new create] },
                     permissible_on: :project,
                     dependencies: :view_finance_entries
          permission :edit_finance_entries,
                     { finance_entries: %i[edit update] },
                     permissible_on: :project,
                     dependencies: :view_finance_entries
          permission :delete_finance_entries,
                     { finance_entries: %i[destroy destroy_dialog] },
                     permissible_on: :project,
                     dependencies: :view_finance_entries
        end

        menu :project_menu,
             :finances,
             { controller: "/finance_entries", action: "index" },
             if: ->(project) { project.module_enabled?(:finances) },
             after: :budgets,
             caption: :project_module_finances,
             icon: "op-budget"
      end

      patches %i[Project]
      patch_with_namespace :Projects, :CopyService

      config.to_prepare do
        # Load filter/order registration (Zeitwerk: queries/finance_entries.rb).
        ::Queries::FinanceEntries::FinanceEntryQuery
      end

      add_cron_jobs do
        {
          FinanceCbrSyncJob: {
            cron: "*/30 * * * *",
            class: "Finance::Cbr::SyncJob"
          }
        }
      end
    end
  end
end
