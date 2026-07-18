# frozen_string_literal: true

module Finances
  class DestroyDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    def initialize(entry:)
      super
      @entry = entry
    end

    private

    attr_reader :entry
  end
end
