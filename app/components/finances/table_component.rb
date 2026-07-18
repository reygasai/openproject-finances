# frozen_string_literal: true

module Finances
  class TableComponent < ::OpPrimer::BorderBoxTableComponent
    columns :entry_date, :amount, :description, :participants, :work_packages, :author

    mobile_columns :entry_date, :amount, :description
    # main_column disables single-line ellipsis so multiple entities remain visible.
    main_column :amount, :description, :participants, :work_packages

    options :current_project, :rate_lookup

    def sortable?
      # Sorting is controlled via SubHeader (sortBy / query orders), not SortHelper.
      # BorderBoxTableComponent has no sort headers; enabling this re-sorts/re-paginates.
      false
    end

    def paginated?
      true
    end

    def has_actions?
      true
    end

    def mobile_title
      I18n.t("finances.label_finance_entries")
    end

    def headers
      [
        [:entry_date, { caption: FinanceEntry.human_attribute_name(:entry_date) }],
        [:amount, { caption: FinanceEntry.human_attribute_name(:amount) }],
        [:description, { caption: FinanceEntry.human_attribute_name(:description) }],
        [:participants, { caption: I18n.t("finances.label_participants") }],
        [:work_packages, { caption: FinanceEntry.human_attribute_name(:work_packages) }],
        [:author, { caption: FinanceEntry.human_attribute_name(:author) }]
      ]
    end

    def blank_title
      I18n.t("finances.label_no_entries")
    end

    def blank_description
      I18n.t("finances.label_no_entries_description")
    end
  end
end
