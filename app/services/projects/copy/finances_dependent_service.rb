# frozen_string_literal: true

module Projects
  module Copy
    class FinancesDependentService < Dependency
      def self.human_name
        I18n.t("project_module_finances")
      end

      def source_count
        source.finance_entries.count
      end

      protected

      def copy_dependency(_params)
        wp_map = state.work_package_id_lookup || {}

        source.finance_entries.find_each do |entry|
          copy_entry(entry, wp_map)
        end
      end

      def copy_entry(source_entry, wp_map)
        attrs = {
          project: target,
          amount: source_entry.amount,
          currency: source_entry.currency,
          entry_date: source_entry.entry_date,
          description: source_entry.description,
          # Preserve source author (may not be a member of the target project).
          author: source_entry.author,
          user_participant_ids: copyable_user_ids(source_entry),
          external_participant_names: source_entry.external_participants.map(&:name),
          work_package_ids: source_entry.work_package_ids.filter_map { |id| wp_map[id] }
        }

        result = FinanceEntries::CreateService
                   .new(user:, contract_class: EmptyContract)
                   .call(attrs)

        add_error!(source_entry.class.to_s, result.errors) if result.failure?
      end

      def copyable_user_ids(source_entry)
        member_ids = target.users.pluck(:id)
        source_entry.user_participant_ids.select { |id| member_ids.include?(id) }
      end
    end
  end
end
