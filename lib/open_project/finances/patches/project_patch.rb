# frozen_string_literal: true

module OpenProject
  module Finances
    module Patches
      module ProjectPatch
        def self.included(receiver)
          receiver.class_eval do
            has_many :finance_entries, dependent: :destroy
            has_many :finance_external_participants, dependent: :destroy
          end
        end
      end
    end
  end
end
