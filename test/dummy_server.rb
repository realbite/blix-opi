require_relative '../lib/blix/opi'

logger = Logger.new(STDOUT)
$VERBOSE=true
c = OPI::Connection.new(:local_port=>4100, :remote_port=>4102, :logger=>logger)


def handle_card_service_request(root)
  "CARD"
end


def handle_service_request(root)
   "SERVICE"
end

count = 0
c.listen do |msg|
  count +=1
  begin
    doc = Nokogiri::XML(msg)
  rescue Exception=>e
    logger.error "XML=>#{e}"
    next
  end

  root = doc.root
  info = root.to_h

  puts "[#{count}] received #{root.name}=>#{info.inspect}"
  if root.name == "CardServiceRequest"
    handle_card_service_request(root)
  elsif root.name == "ServiceRequest"
    handle_service_request(root)
  else
    "invalid request"
  end
end
