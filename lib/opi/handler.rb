# class to handle device requests from the EPS

module OPI
  class Handler

   # <?xml version="1.0" encoding="UTF-8"?>
  # <DeviceResponse RequestID="2.3" WorkstationID="1" OverallResult="Success" ApplicationSender="MICROS"
  # RequestType="Output">
  # <Output OutDeviceTarget="Printer" OutResult="Success"/>
# </DeviceResponse>
    def respond

    end

    # the RequestType can be of the following
    #   Input
    #   Output
    #   SecureInput
    #   SecureOutput
    #   AbortInput
    #   AbortOutput
    #   RepeatLastMessage
    #   Event

    def parse_device_request(xml)
      raise OPI::Error, 'missing XML' unless xml

      begin
        doc = Nokogiri::XML(xml){ |conf| conf.noblanks }
      rescue Exception
        raise OPI::Error, 'invalid XML'
      end

      node = doc&.css('DeviceRequest')&.first
      raise OPI::Error, 'invalid device request' unless node
      #input = node&.css('Input')&.first  # only one input allowed
      output   = node&.css('Output')     # can have up to two outputs
      out = node.to_h
      #out['Input'] = input.to_s if input
      if output
        out['Output'] = output.map{|n|
          h = n.to_h
          h['device'] = n.attr('OutDeviceTarget')
          h['lines'] = n.children.map{|c|
            c.to_h.merge(:text=>c.text, :type=>c.name)
          }
          h
        }
      end
      out
    end




    def process(msg)

    end
  end
end
