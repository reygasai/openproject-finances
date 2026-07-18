# frozen_string_literal: true

module Finances
  class EntryDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    def initialize(entry:, project:)
      super
      @entry = entry
      @project = project
    end

    private

    attr_reader :entry, :project

    def title
      if entry.persisted?
        I18n.t("finances.label_edit_finance_entry")
      else
        I18n.t("finances.label_new_finance_entry")
      end
    end

    def form_url
      if entry.persisted?
        helpers.finance_entry_path(entry)
      else
        helpers.project_finance_entries_path(project)
      end
    end

    def form_method
      entry.persisted? ? :patch : :post
    end
  end
end
