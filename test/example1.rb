# setup payment interface. use the dummy handler to
# process the requests.

require './lib/blix/opi'

$VERBOSE=true

class MyPrinterHandler < OPI::Handler

  def output(info)
    puts "output==>#{info.inspect}"
  end

end

options = {
       :application_id=>'testPOD',
       :workstation_id=>'term1',
       :local_port =>'4102',
       :remote_port   =>'4100',
       :timeout_0  =>1,
       :timeout_1  =>1,
    }


term = OPI::Terminal.new( options )
term.register_device OPI::Device::Printer, MyPrinterHandler.new

Thread.new{ term.listen() }

puts "login==>" + term.login().inspect    # returns true/false

puts "pay==>"   + term.card_payment(22.5, '123BCX').inspect

puts "logoff==>"+ term.logoff.inspect

puts "done.."
