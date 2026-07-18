# frozen_string_literal: true

module Finances
  class ParticipantsComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(entry:)
      super
      @entry = entry
    end

    def call
      items = participant_items
      return "—" if items.empty?

      flex_layout(classes: "flex-wrap gap-1") do |flex|
        items.each do |item|
          flex.with_column { item }
        end
      end
    end

    private

    def participant_items
      items = []

      @entry.user_participants.each do |user|
        items << render(Users::AvatarComponent.new(user:, size: :mini, link: true, show_name: true))
      end

      @entry.external_participants.each do |external|
        items << render(Primer::Beta::Label.new) { external.name }
      end

      items
    end
  end
end
