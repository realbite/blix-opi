require 'spec_helper'
require 'json'

module OPI
  describe Protocol do

    it "should parse service response" do
      r = Protocol.new(Connection.new, :workstation_id=>'xx', :application_id=>'yy')
      xml = File.read 'resources/service_response_success.xml'
      status = r.parse_service_response(xml)
      puts JSON.pretty_generate(status)
      expect(status['success']).to be true

      xml = File.read 'resources/service_response_failure.xml'
      status = r.parse_service_response(xml)
      expect(status['success']).to be false
    end

    it "should parse card service response" do
      r = Protocol.new(Connection.new, :workstation_id=>'xx', :application_id=>'yy')
      xml = File.read 'resources/card_service_response.xml'
      status = r.parse_card_response(xml)
      puts JSON.pretty_generate(status)
      expect(status['success']).to be true

      xml = File.read 'resources/card_service_response2.xml'
      status = r.parse_card_response(xml)
      puts JSON.pretty_generate(status)
      expect(status['success']).to be true

    end

    it "should parse device request" do
      r = Protocol.new(Connection.new, :workstation_id=>'xx', :application_id=>'yy')
      xml = File.read 'resources/device_request1.xml'
      status = r.parse_device_request(xml)
      puts JSON.pretty_generate(status)


      xml = File.read 'resources/device_request2.xml'
      status = r.parse_device_request(xml)
      puts JSON.pretty_generate(status)
    end


  end

end
