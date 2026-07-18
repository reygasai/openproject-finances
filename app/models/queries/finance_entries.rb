# frozen_string_literal: true

module Queries
  module FinanceEntries
    ::Queries::Register.register(FinanceEntryQuery) do
      filter Filters::ProjectFilter
      filter Filters::EntryDateFilter
      filter Filters::CurrencyFilter
      filter Filters::AuthorFilter
      filter Filters::EntryTypeFilter
      filter Filters::UserParticipantFilter
      filter Filters::WorkPackageFilter
      filter Filters::DescriptionFilter

      order Orders::DefaultOrder
    end
  end
end
