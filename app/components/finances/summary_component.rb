# frozen_string_literal: true

module Finances
  class SummaryComponent < ApplicationComponent
    include OpTurbo::Streamable
    include Finances::AmountHelper

    def initialize(totals:)
      super
      @totals = totals
    end

    def call
      component_wrapper do
        render(Primer::Beta::BorderBox.new) do |box|
          box.with_header { I18n.t("finances.label_summary") }
          box.with_row do
            concat content_tag(
              :div,
              "#{I18n.t('finances.label_total_rub')}: #{format('%.2f', @totals.total_rub)} RUB",
              class: "text-bold"
            )
            concat currency_breakdown
            concat missing_warning if @totals.missing_rate_count.positive?
          end
        end
      end
    end

    private

    def currency_breakdown
      return "".html_safe if @totals.by_currency.size <= 1

      list = @totals.by_currency.map { |code, sum| "#{format('%.2f', sum)} #{code}" }.join(" · ")
      content_tag(:div, "#{I18n.t('finances.label_by_currency')}: #{list}", class: "color-fg-muted mt-1")
    end

    def missing_warning
      content_tag(
        :div,
        I18n.t("finances.messages.missing_rates", count: @totals.missing_rate_count),
        class: "flash flash-warning mt-2"
      )
    end
  end
end
