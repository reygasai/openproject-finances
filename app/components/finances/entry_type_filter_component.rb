# frozen_string_literal: true

module Finances
  class EntryTypeFilterComponent < OpPrimer::QuickFilter::SegmentedControlComponent
    def initialize(query:, project:)
      super(
        name: I18n.t("finances.label_entry_type"),
        query:,
        filter_key: :entry_type,
        path_args: [project, :finance_entries]
      )

      with_item(label: I18n.t("finances.label_all_entries"), value: nil)
      with_item(label: I18n.t("finances.label_income"), value: "income")
      with_item(label: I18n.t("finances.label_expense"), value: "expense")
    end
  end
end
