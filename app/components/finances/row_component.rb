# frozen_string_literal: true

module Finances
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    include Finances::AmountHelper

    def entry_date
      helpers.format_date(model.entry_date)
    end

    def amount
      finance_amount_display(model, lookup: table.options[:rate_lookup])
    end

    def description
      helpers.truncate(model.description.to_s, length: 120)
    end

    def participants
      render(Finances::ParticipantsComponent.new(entry: model))
    end

    def work_packages
      return "—" if model.work_packages.empty?

      flex_layout(classes: "flex-wrap gap-1") do |flex|
        model.work_packages.each do |wp|
          flex.with_column do
            helpers.link_to_work_package(wp, link_subject: true)
          end
        end
      end
    end

    def author
      helpers.link_to_user(model.author)
    end

    def button_links
      [action_menu]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": I18n.t(:label_more),
                              scheme: :invisible,
                              size: :small)

        if User.current.allowed_in_project?(:edit_finance_entries, model.project)
          menu.with_item(
            tag: :a,
            label: I18n.t(:button_edit),
            href: helpers.edit_finance_entry_path(model),
            content_arguments: { data: { turbo_stream: true } }
          )
        end

        menu.with_item(
          tag: :a,
          label: I18n.t("finances.label_history"),
          href: helpers.history_finance_entry_path(model),
          content_arguments: { data: { turbo_stream: true } }
        )

        if User.current.allowed_in_project?(:delete_finance_entries, model.project)
          menu.with_item(
            tag: :a,
            label: I18n.t(:button_delete),
            href: helpers.destroy_dialog_finance_entry_path(model),
            scheme: :danger,
            content_arguments: { data: { turbo_stream: true } }
          )
        end
      end
    end
  end
end
