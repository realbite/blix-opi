require 'spec_helper'
require 'json'

module OPI
  describe Protocol do

    before do
      @p = Protocol.new
    end

    it "should parse xml" do
      expect{@p.parse_xml(nil)}.to raise_error OPI::Error
      xml = File.read('resources/device_request1.xml')
      doc = @p.parse_xml xml
      expect(doc.to_s.length).to be > 100
    end

    it "should parse a card response" do
      xml = File.read('resources/device_request1.xml')
      expect{@p.parse_card_response(xml)}.to raise_error OPI::Error
      xml = File.read('resources/card_service_response.xml')
      info = @p.parse_card_response(xml)
      expect(info["RequestType"]).to eq "CardPayment"
    end

    it "should parse a service response" do
      xml = File.read('resources/device_request1.xml')
      expect{@p.parse_service_response(xml)}.to raise_error OPI::Error
      xml = File.read('resources/service_response_success.xml')
      info = @p.parse_service_response(xml)
      expect(info["RequestType"]).to eq "Administration"
    end

    it "should parse a device request" do
      xml = File.read('resources/service_response_success.xml')
      expect{@p.parse_device_request(xml)}.to raise_error OPI::Error
        xml = File.read('resources/device_request1.xml')
      info = @p.parse_device_request(xml)
      expect(info["RequestType"]).to eq "Output"
    end

    it "should format a card request" do


    end

    it "should format a service request" do


    end

    it "should format a device response" do


    end

  end
end
