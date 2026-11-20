# frozen_string_literal: true

module OpenProject
  module Finances
    module Patches
      module Projects
        module CopyServicePatch
          def self.included(base)
            # Prepend instead of defining the method (or aliasing it) directly
            # on the singleton class. Other plugins (e.g. backlogs) prepend their
            # own modules to the singleton class as well; a method defined
            # directly on the singleton class would be picked up by their
            # `super` call and cause infinite recursion.
            base.singleton_class.prepend(ClassMethods)
          end

          module ClassMethods
            def copy_dependencies
              super + [::Projects::Copy::FinancesDependentService]
            end
          end
        end
      end
    end
  end
end
