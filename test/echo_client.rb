require_relative '../lib/blix/opi'
require 'logger'

l = Logger.new(STDOUT)
$VERBOSE=true
c = OPI::Connection.new(:local_port=>2000, :remote_port=>2000, :logger=>l, :timeout_1=>1)

100.times do
   puts c.request('ħello ') rescue nil
end


# r = OPI::Request.new
# 5.times do
#   r.login rescue nil
# end
#
# r.card_payment(12.34)
# r.card_payment(34.56,"987/2")
