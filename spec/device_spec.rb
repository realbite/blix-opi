require 'spec_helper'
require 'json'

module OPI
  describe Handler do

    it "should parse device request" do
      r = Handler.new
      xml = File.read 'resources/device_request1.xml'
      status = r.parse_device_request(xml)
      puts JSON.pretty_generate(status)


      xml = File.read 'resources/device_request2.xml'
      status = r.parse_device_request(xml)
      puts JSON.pretty_generate(status)
    end



  end

end
