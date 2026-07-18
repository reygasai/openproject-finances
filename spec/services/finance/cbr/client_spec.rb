# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Finance::Cbr::Client do
  describe "#parse_daily via fetch_daily" do
    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="windows-1251"?>
        <ValCurs Date="11.07.2026" name="Foreign Currency Market">
          <Valute ID="R01235">
            <NumCode>840</NumCode>
            <CharCode>USD</CharCode>
            <Nominal>1</Nominal>
            <Name>US Dollar</Name>
            <Value>90,1234</Value>
          </Valute>
          <Valute ID="R01239">
            <NumCode>978</NumCode>
            <CharCode>EUR</CharCode>
            <Nominal>1</Nominal>
            <Name>Euro</Name>
            <Value>100,5000</Value>
          </Valute>
        </ValCurs>
      XML
    end

    before do
      stub_request(:get, %r{cbr\.ru/scripts/XML_daily\.asp})
        .to_return(status: 200, body: xml.encode("windows-1251"), headers: { "Content-Type" => "application/xml" })
    end

    it "parses rates and date" do
      payload = described_class.new.fetch_daily(date: Date.new(2026, 7, 11))

      expect(payload[:rate_date]).to eq(Date.new(2026, 7, 11))
      usd = payload[:rates].find { |r| r[:currency_code] == "USD" }
      expect(usd[:rate]).to eq(BigDecimal("90.1234"))
      expect(usd[:nominal]).to eq(1)
    end

    context "with invalid rate nodes" do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="windows-1251"?>
          <ValCurs Date="11.07.2026" name="Foreign Currency Market">
            <Valute ID="R01235">
              <NumCode>840</NumCode>
              <CharCode>USD</CharCode>
              <Nominal>1</Nominal>
              <Name>US Dollar</Name>
              <Value>90,1234</Value>
            </Valute>
            <Valute ID="bad">
              <CharCode>XXX</CharCode>
              <Nominal>1</Nominal>
              <Value></Value>
            </Valute>
            <Valute ID="bad2">
              <CharCode>YYY</CharCode>
              <Nominal>1</Nominal>
              <Value>not-a-number</Value>
            </Valute>
          </ValCurs>
        XML
      end

      it "skips invalid nodes instead of failing" do
        payload = described_class.new.fetch_daily(date: Date.new(2026, 7, 11))

        expect(payload[:rates].map { |r| r[:currency_code] }).to eq(["USD"])
      end
    end
  end

  describe "#fetch_currencies" do
    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="windows-1251"?>
        <Valuta>
          <Item ID="R01235">
            <Name>US Dollar</Name>
            <EngName>US Dollar</EngName>
            <Nominal>1</Nominal>
            <ParentCode>R01235</ParentCode>
            <ISO_Num_Code>840</ISO_Num_Code>
            <ISO_Char_Code>USD</ISO_Char_Code>
          </Item>
        </Valuta>
      XML
    end

    before do
      stub_request(:get, %r{cbr\.ru/scripts/XML_valFull\.asp})
        .to_return(status: 200, body: xml.encode("windows-1251"), headers: { "Content-Type" => "application/xml" })
    end

    it "parses currency catalog" do
      currencies = described_class.new.fetch_currencies

      expect(currencies).to include(hash_including(code: "USD", name: "US Dollar", active: true))
    end

    context "when response uses Windows-1251" do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="windows-1251"?>
          <Valuta>
            <Item ID="R01020">
              <Name>Австралийский доллар</Name>
              <ISO_Char_Code>AUD</ISO_Char_Code>
            </Item>
          </Valuta>
        XML
      end

      it "decodes Cyrillic names as UTF-8" do
        currencies = described_class.new.fetch_currencies

        expect(currencies).to include(hash_including(code: "AUD", name: "Австралийский доллар"))
      end
    end

    context "when response is already UTF-8" do
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Valuta>
            <Item ID="R01020">
              <Name>Австралийский доллар</Name>
              <EngName>Australian Dollar</EngName>
              <Nominal>1</Nominal>
              <ISO_Char_Code>AUD</ISO_Char_Code>
            </Item>
          </Valuta>
        XML
      end

      before do
        stub_request(:get, %r{cbr\.ru/scripts/XML_valFull\.asp})
          .to_return(status: 200, body: xml.dup.force_encoding(Encoding::BINARY),
                     headers: { "Content-Type" => "application/xml; charset=utf-8" })
      end

      it "keeps Cyrillic names readable" do
        currencies = described_class.new.fetch_currencies

        expect(currencies).to include(hash_including(code: "AUD", name: "Австралийский доллар"))
      end
    end

    context "when a proxy returns mojibake encoded as UTF-8" do
      let(:name) { "Австралийский доллар" }
      let(:garbled_name) { name.dup.force_encoding("windows-1251").encode(Encoding::UTF_8) }
      let(:xml) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <Valuta>
            <Item ID="R01020">
              <Name>#{garbled_name}</Name>
              <ISO_Char_Code>AUD</ISO_Char_Code>
            </Item>
          </Valuta>
        XML
      end

      before do
        stub_request(:get, %r{cbr\.ru/scripts/XML_valFull\.asp})
          .to_return(status: 200, body: xml, headers: { "Content-Type" => "application/xml; charset=utf-8" })
      end

      it "repairs the currency name before returning it" do
        currencies = described_class.new.fetch_currencies

        expect(currencies).to include(hash_including(code: "AUD", name: name))
      end
    end
  end
end
