# frozen_string_literal: true

module OpenProject
  module Finances
    module Patches
      module Projects
        module CopyServicePatch
          def self.included(base)
            class << base
              alias_method :copy_dependencies_without_finances, :copy_dependencies

              def copy_dependencies
                copy_dependencies_without_finances + [::Projects::Copy::FinancesDependentService]
              end
            end
          end
        end
      end
    end
  end
end
