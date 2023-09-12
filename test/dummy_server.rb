require_relative '../lib/blix/opi'


class Server

  def initialize
    @logger = Logger.new(STDOUT)
    @connection = OPI::Connection.new(:local_port=>4100, :remote_port=>4102, :logger=>@logger, :verbose=>true)
    @parser = OPI::Protocol.new
  end

  def handle_card_service_request(root)
    info = root.to_h
    type = info['RequestType']
    @parser.card_response_xml(info, OPI::Result::Success) do |xml|
      xml.Terminal 'TerminalID'=>'1', 'TerminalBatch'=>"62", 'STAN'=>"724"
      if type == 'CardPayment'
        amount   = root&.css('TotalAmount')&.first.text
        xml.Tender do |xml|
          xml.TotalAmount amount, 'Currency'=>"EUR"
          xml.Authorization 'AcquirerID'=>"BUYPASS", 'CardPAN'=>"0000000000000001"
        end
      end
    end
  end


  def handle_service_request(root)
     info = root.to_h
     @parser.service_response_xml(info, OPI::Result::Success)
  end

  def run
    @logger.info "server started ..."
    count = 0
    @connection.listen do |msg|
      count +=1
      begin
        doc = Nokogiri::XML(msg)
      rescue Exception=>e
        @logger.error "XML=>#{e}"
        next "error"
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
  end
end

Server.new.run
