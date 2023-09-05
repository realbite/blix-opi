require_relative '../lib/blix/opi'

l = Logger.new(STDOUT)
$VERBOSE=true
c = OPI::Connection.new(:local_port=>2000, :remote_port=>2000, :logger=>l)

count = 0
c.listen do |msg|
  count +=1
  puts "[#{count}] received #{msg}"
  #sleep 2
  "[echo #{Time.now}] => #{msg}"
end
