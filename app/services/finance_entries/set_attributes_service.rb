# frozen_string_literal: true

module FinanceEntries
  class SetAttributesService < ::BaseServices::SetAttributes
    private

    def set_attributes(params)
      user_ids = params.delete(:user_participant_ids)
      external_names = params.delete(:external_participant_names)
      wp_ids = params.delete(:work_package_ids)

      super

      set_user_participants(user_ids) unless user_ids.nil?
      set_external_participants(external_names) unless external_names.nil?
      set_work_packages(wp_ids) unless wp_ids.nil?
    end

    def set_default_attributes(_params)
      model.change_by_system do
        model.author = user if model.author.nil?
        model.entry_date ||= Date.current
        model.currency ||= "RUB"
      end
    end

    def set_user_participants(user_ids)
      ids = Array(user_ids).map(&:presence).compact.map(&:to_i).uniq
      model.user_participants = User.where(id: ids)
      touch_for_association_journal!
    end

    def set_external_participants(names)
      return unless model.project

      normalized = Array(names).map { |n| n.to_s.strip.presence }.compact.uniq
      model.external_participants = normalized.map do |name|
        FinanceExternalParticipant.find_or_create_for_project!(project: model.project, name:)
      end
      touch_for_association_journal!
    end

    def set_work_packages(wp_ids)
      ids = Array(wp_ids).map(&:presence).compact.map(&:to_i).uniq
      model.requested_work_package_ids = ids
      scope = model.project ? model.project.work_packages : WorkPackage
      model.work_packages = scope.where(id: ids)
      touch_for_association_journal!
    end

    # Association-only edits do not dirty finance_entries columns; force an update
    # so after_save journaling runs and updated_at advances.
    def touch_for_association_journal!
      model.change_by_system do
        model.updated_at = Time.current
      end
    end
  end
end
