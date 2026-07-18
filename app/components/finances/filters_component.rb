# frozen_string_literal: true

module Finances
  class FiltersComponent < Filter::FilterComponent
    options :project

    def turbo_requests? = true

    def allowed_filters
      super
        .select { |f| allowed_filter?(f) }
        .sort_by(&:human_name)
    end

    private

    def allowed_filter?(filter)
      [
        Queries::FinanceEntries::Filters::EntryDateFilter,
        Queries::FinanceEntries::Filters::CurrencyFilter,
        Queries::FinanceEntries::Filters::AuthorFilter,
        Queries::FinanceEntries::Filters::EntryTypeFilter,
        Queries::FinanceEntries::Filters::UserParticipantFilter,
        Queries::FinanceEntries::Filters::WorkPackageFilter,
        Queries::FinanceEntries::Filters::DescriptionFilter
      ].any? { |clazz| filter.is_a?(clazz) }
    end
  end
end
