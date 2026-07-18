# frozen_string_literal: true

require "net/http"
require "nokogiri"

module Finance
  module Cbr
    class Client
      DAILY_URL = "https://www.cbr.ru/scripts/XML_daily.asp"
      VAL_FULL_URL = "https://www.cbr.ru/scripts/XML_valFull.asp"

      def fetch_daily(date: Date.current)
        uri = URI(DAILY_URL)
        uri.query = URI.encode_www_form(date_req: date.strftime("%d/%m/%Y"))
        body = get(uri)
        parse_daily(body)
      end

      def fetch_currencies
        body = get(URI(VAL_FULL_URL))
        parse_currencies(body)
      end

      private

      def get(uri)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                                       open_timeout: 10,
                                                       read_timeout: 20) do |http|
          http.request(Net::HTTP::Get.new(uri))
        end

        raise "CBR HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        decode_cbr_body(response.body)
      end

      def decode_cbr_body(body)
        raw = body.to_s.dup.force_encoding(Encoding::BINARY)

        # Modern CBR responses (and some proxies) may already be UTF-8,
        # regardless of the encoding declared in the XML prologue.
        utf8 = raw.dup.force_encoding(Encoding::UTF_8)
        return normalize_xml_encoding_declaration(utf8) if utf8.valid_encoding?

        normalize_xml_encoding_declaration(
          raw.force_encoding("windows-1251").encode(Encoding::UTF_8)
        )
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        normalize_xml_encoding_declaration(
          body.to_s.dup.force_encoding(Encoding::UTF_8)
              .encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
        )
      end

      # After converting bytes to a Ruby UTF-8 string, the XML prologue may still
      # claim windows-1251. Nokogiri would then re-decode and garble Cyrillic.
      def normalize_xml_encoding_declaration(xml)
        xml.sub(/encoding\s*=\s*["'][^"']*["']/i, 'encoding="UTF-8"')
      end

      def parse_daily(xml)
        doc = Nokogiri::XML(xml)
        rate_date = parse_cbr_date(doc.at_xpath("/ValCurs")&.[]("Date")) || Date.current

        rates = doc.xpath("//Valute").filter_map do |node|
          code = node.at_xpath("CharCode")&.text&.strip
          next if code.blank?

          rate = parse_decimal(node.at_xpath("Value")&.text)
          next if rate.nil? || rate <= 0

          {
            currency_code: code,
            rate_date:,
            nominal: [node.at_xpath("Nominal")&.text.to_i, 1].max,
            rate:
          }
        end

        { rate_date:, rates: }
      end

      def parse_currencies(xml)
        doc = Nokogiri::XML(xml)
        doc.xpath("//Item").filter_map do |node|
          code = node.at_xpath("ISO_Char_Code")&.text&.strip
          next if code.blank? || code.length != 3

          {
            code:,
            name: repair_mojibake(node.at_xpath("Name")&.text&.strip).presence || code,
            active: true
          }
        end
      end

      # Some proxies return already-garbled UTF-8 (for example,
      # "РђРІСЃС‚СЂР°Р»РёР№СЃРєРёР№" instead of "Австралийский").
      # Reversing the accidental Windows-1251 conversion is safe only when
      # it produces valid UTF-8 and reduces characteristic mojibake pairs.
      def repair_mojibake(value)
        text = value.to_s
        score = mojibake_score(text)
        return text if score.zero?

        repaired = text.encode("windows-1251").force_encoding(Encoding::UTF_8)
        return text unless repaired.valid_encoding? && mojibake_score(repaired) < score

        repaired
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        text
      end

      def mojibake_score(value)
        value.scan(/[РС][^\x00-\x7F]/).size
      end

      def parse_cbr_date(value)
        return if value.blank?

        Date.strptime(value, "%d.%m.%Y")
      rescue ArgumentError
        nil
      end

      def parse_decimal(value)
        cleaned = value.to_s.tr(",", ".").strip
        return if cleaned.blank?

        BigDecimal(cleaned)
      rescue ArgumentError
        nil
      end
    end
  end
end
