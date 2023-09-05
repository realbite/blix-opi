require 'spec_helper'


module OPI

  class FileConnection

    def initialize(filename)
      @filename = filename
    end

    def request(xml)
      puts xml
      File.read(@filename)
    end

  end

  class MyHandler < Handler

    def output(info)
      raise 'myhandler error' if info[:raise]
      info['return'] || Result::Success
    end

  end

  describe Terminal do

    # it "should require application and workstation id" do
    #   expect{Terminal.new()}.to raise_error ArgumentError
    #   expect{Terminal.new(:application_id=>'xxx')}.to raise_error ArgumentError
    #   expect{Terminal.new(:workstation_id=>'yyy')}.to raise_error ArgumentError
    #   expect{Terminal.new(:application_id=>'xxx',:workstation_id=>'yyy')}.not_to raise_error
    # end

    it "should set default options" do
      term =  Terminal.new(:application_id=>'xxx',:workstation_id=>'yyy', :local_host=>'0.0.0.0')
      puts term.opts.inspect
      puts term.opts[:logger].inspect
    end

    it "should perform login" do
      term = Terminal.new(:connection=>FileConnection.new('resources/service_response_success.xml'))
      expect(term.login).to eq true
      term = Terminal.new(:connection=>FileConnection.new('resources/service_response_failure.xml'))
      expect(term.login).to eq false
    end

    it "should perform logoff" do
      term = Terminal.new(:connection=>FileConnection.new('resources/service_response_success.xml'))
      expect(term.logoff).to eq true
      term = Terminal.new(:connection=>FileConnection.new('resources/service_response_failure.xml'))
      expect(term.logoff).to eq false
    end

    it "should perform card payment" do
      term = Terminal.new(:connection=>FileConnection.new('resources/card_service_response.xml'))
      puts term.card_payment(12.34)
    end

    it "should calculate final status" do
      term = Terminal.new
      expect(term.calculate_overall_status([])).to eq Result::Failure
      expect(term.calculate_overall_status([Result::Failure])).to eq Result::Failure
      expect(term.calculate_overall_status([Result::Success])).to eq Result::Success
      expect(term.calculate_overall_status([Result::Success,Result::Success])).to eq Result::Success
      expect(term.calculate_overall_status([Result::Success,Result::Failure])).to eq Result::Failure
    end

    it "should process device output handlers" do
      term = Terminal.new
      out1 = {'device'=>Device::Printer, 'return'=>Result::Aborted}
      out2 = {'device'=>Device::PrinterReceipt}
      out3 = {'device'=>Device::PrinterReceipt, :raise=>true}
      expect(term.process_device_outputs([])).to eq []
      expect(term.process_device_outputs([out1])).to eq [Result::DeviceUnavailable]
      expect(term.process_device_outputs([out1,out2])).to eq [Result::DeviceUnavailable,Result::DeviceUnavailable]
      term.register_device(Device::PrinterReceipt, MyHandler.new)
      expect(term.process_device_outputs([out1,out2])).to eq [Result::DeviceUnavailable,Result::Success]
      term.register_device(Device::Printer, MyHandler.new)
      expect(term.process_device_outputs([out1,out2])).to eq [Result::Aborted,Result::Success]
      expect(term.process_device_outputs([out1,out3])).to eq [Result::Aborted,Result::Failure]
    end

    it "should handle a device request" do
      term =  Terminal.new
      term.register_device(Device::Printer, MyHandler.new)
      xml = File.read('resources/device_request1.xml')
      xml_out = term.handle_device_request(xml)
      puts xml_out
    end

  end
end
