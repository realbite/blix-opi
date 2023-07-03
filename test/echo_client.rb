require_relative '../lib/blix/opi'

c = OPI::Connection.new

# 100.times do
#    puts c.request('ħello ')
# end


r = OPI::Request.new
5.times do
  r.login rescue nil
end

r.card_payment(12.34)
r.card_payment(34.56,"987/2")
