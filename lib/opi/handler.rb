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

    

    def process(xml)
      begin
        request = parse_device_request(xml)
      rescue OPI::Error=>e
        Response.new(:result=>Result::ParsingError)
      rescue Exception=>e
        Response.new(:result=>Result::FormatError)
      end

      type = request['RequestType']
      # this is the main request type. an inpu reqest can also contain
      # output elements that are eg a prompt.

      # go through each output and process through the relevant handler..
      results = []
      overall_result = Result::Success
      request['Output'].each do |info|
        device = info['device']
        handler = Handler.get_handler(device)
        results << if handler
          begin
            res = handler.process(info)
            res || Result::Failure
          rescue Exception=>e
            Result::Failure
          end
        else
          Result::DeviceUnavailable
        end
      end
      # if the request type is output then only check the ou
      # if we have all successes then the overall result is success.
      # if we have at least one success and failures then partial success
      # all failures the overall failure.

      #



    end
  end
end
