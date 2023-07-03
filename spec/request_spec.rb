require 'spec_helper'
require 'json'

module OPI
  describe Request do

    it "should parse service response" do
      r = Request.new
      xml = File.read 'resources/service_response_success.xml'
      status = r.parse_service_response(xml)
      puts JSON.pretty_generate(status)
      expect(status['success']).to be true

      xml = File.read 'resources/service_response_failure.xml'
      status = r.parse_service_response(xml)
      expect(status['success']).to be false
    end

    it "should parse card service response" do
      r = Request.new
      xml = File.read 'resources/card_service_response.xml'
      status = r.parse_card_response(xml)
      puts JSON.pretty_generate(status)
      expect(status['success']).to be true

      xml = File.read 'resources/card_service_response2.xml'
      status = r.parse_card_response(xml)
      puts JSON.pretty_generate(status)
      expect(status['success']).to be true

    end

  end

end
