require 'spec_helper'


module OPI
  describe Terminal do

    it "should require application and workstation id" do
      expect{Terminal.new()}.to raise_error ArgumentError
      expect{Terminal.new(:application_id=>'xxx')}.to raise_error ArgumentError
      expect{Terminal.new(:workstation_id=>'yyy')}.to raise_error ArgumentError
      expect{Terminal.new(:application_id=>'xxx',:workstation_id=>'yyy')}.not_to raise_error
    end

    it "should set default options" do
      term =  Terminal.new(:application_id=>'xxx',:workstation_id=>'yyy', :local_host=>'0.0.0.0')
      puts term.opts.inspect
      puts term.opts[:logger].inspect
    end

  end
end
