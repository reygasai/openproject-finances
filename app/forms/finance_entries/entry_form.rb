# frozen_string_literal: true

class FinanceEntries::EntryForm < ApplicationForm
  DIALOG_ID = "finance-entry-dialog"

  form do |f|
    f.text_field(
      name: :amount,
      label: FinanceEntry.human_attribute_name(:amount),
      required: true,
      caption: I18n.t("finances.captions.amount_signed")
    )

    f.select_list(
      name: :currency,
      label: FinanceEntry.human_attribute_name(:currency),
      required: true,
      include_blank: false
    ) do |list|
      currencies_for_select.each do |currency|
        list.option(
          label: currency_option_label(currency),
          value: currency.code,
          selected: model.currency == currency.code
        )
      end
    end

    f.single_date_picker(
      name: :entry_date,
      label: FinanceEntry.human_attribute_name(:entry_date),
      required: true,
      leading_visual: { icon: :calendar },
      value: model.entry_date&.iso8601,
      datepicker_options: { inDialog: DIALOG_ID }
    )

    f.text_area(
      name: :description,
      label: FinanceEntry.human_attribute_name(:description),
      rows: 3
    )

    # Sentinel so a cleared multi-autocompleter still submits the key.
    f.hidden(name: "finance_entry[user_participant_ids][]", value: "", scope_name_to_model: false)

    f.autocompleter(
      name: :user_participant_ids,
      label: I18n.t("finances.label_user_participants"),
      autocomplete_options: {
        component: "opce-user-autocompleter",
        url: ::API::V3::Utilities::PathHelper::ApiV3Path.principals,
        resource: "principals",
        searchKey: "any_name_attribute",
        filters: user_participant_filters,
        multiple: true,
        closeOnSelect: false,
        hideSelected: true,
        focusDirectly: false,
        defaultData: true,
        inputValue: model.user_participant_ids.map(&:to_s),
        appendTo: "##{DIALOG_ID}",
        isOpenedInModal: true,
        hoverCards: true
      }
    )

    f.text_field(
      name: :external_participant_names_input,
      label: I18n.t("finances.label_external_participants"),
      caption: I18n.t("finances.captions.external_participants"),
      value: model.external_participants.map(&:name).join(", ")
    )

    f.hidden(name: "finance_entry[work_package_ids][]", value: "", scope_name_to_model: false)

    f.autocompleter(
      name: :work_package_ids,
      label: FinanceEntry.human_attribute_name(:work_packages),
      autocomplete_options: {
        component: "opce-autocompleter",
        url: ::API::V3::Utilities::PathHelper::ApiV3Path.work_packages,
        resource: "work_packages",
        searchKey: "typeahead",
        filters: [
          { name: "project_id", operator: "=", values: [model.project_id.to_s] }
        ],
        multiple: true,
        closeOnSelect: false,
        hideSelected: true,
        focusDirectly: false,
        defaultData: true,
        inputValue: model.work_package_ids.map(&:to_s),
        appendTo: "##{DIALOG_ID}",
        isOpenedInModal: true
      }
    )
  end

  private

  def user_participant_filters
    [
      { name: "type", operator: "=", values: %w[User] },
      { name: "member", operator: "=", values: [model.project_id.to_s] },
      {
        name: "status",
        operator: "=",
        values: [Principal.statuses[:active], Principal.statuses[:invited]].map(&:to_s)
      }
    ]
  end

  def currencies_for_select
    active = FinanceCurrency.active.order(:code).to_a
    current_code = model.currency.to_s.upcase
    return active if current_code.blank? || active.any? { |c| c.code == current_code }

    inactive = FinanceCurrency.find_by(code: current_code)
    inactive ? [inactive] + active : active
  end

  def currency_option_label(currency)
    label = "#{currency.code} — #{currency.name}"
    return label if currency.active?

    "#{label} (#{I18n.t('finances.label_inactive_currency')})"
  end
end
