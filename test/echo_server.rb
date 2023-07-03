require_relative '../lib/blix/opi'

c = OPI::Connection.new

count = 0
c.listen do |msg|
  count +=1
  puts "[#{count}] received #{msg}"
  #sleep 2
  "[echo #{Time.now}] => #{msg}"
end
