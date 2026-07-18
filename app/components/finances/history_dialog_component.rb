# frozen_string_literal: true

module Finances
  class HistoryDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    def initialize(entry:)
      super
      @entry = entry
      @journals = entry.journals.includes(:user).order(version: :desc)
    end

    private

    attr_reader :entry, :journals
  end
end
