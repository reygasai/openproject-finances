# frozen_string_literal: true

module Finances
  module AmountHelper
    # Formats amount for table cells. Conversion is display-only.
    # Pass +lookup+ (Finance::ExchangeRateLookup) to avoid N+1 rate queries.
    def finance_amount_display(entry, lookup: nil)
      amount = format("%.2f", entry.amount)
      return "#{amount} #{entry.currency}" if entry.currency == "RUB"

      conversion = Finance::ConvertToRub.call(
        amount: entry.amount,
        currency: entry.currency,
        on: entry.entry_date,
        lookup:
      )

      if conversion
        "#{amount} #{entry.currency} " \
          "(#{I18n.l(conversion.rate_date)}: #{format('%.2f', conversion.amount_rub)} RUB)"
      else
        "#{amount} #{entry.currency} (#{I18n.t('finances.label_rate_unavailable')})"
      end
    end
  end
end
