# frozen_string_literal: true

module OPI
  # perform requests to the server... format the request into
  # OPI protocol xml then send to the server using the connection.
  # parse the returned xml and extract key fields to use
  # as an appropriate return value.
  class Protocol

    HEADER = '<?xml version="1.0" encoding="UTF-8"?>'

    def initialize(connection, options)
      @workstation_id = options[:workstation_id]
      @application_id = options[:application_id]
      @request_prefix = Time.now.to_i
      @request_id     = 0
      @connection     = connection
      raise ArgumentError,"workstation_id required" unless @workstation_id
      raise ArgumentError,"application_id required" unless @application_id
      raise ArgumentError,"invalid connection" unless connection.kind_of?(OPI::Connection)
    end

    def next_id
      @request_id += 1
      "#{@request_prefix}_#{@request_id}"
    end

    def time_stamp
      Time.now.xmlschema(3)
    end

    def request_params(type)
      [
        'RequestType' => type,
        'ApplicationSender' => @application_id, # Identifies the application sending the request.
        'WorkstationID' => @workstation_id,
        'RequestID' => next_id
      ]
    end

    def service_request(type, &block)
      XmlBuilder.new(:header => HEADER) do |xml|
        xml.ServiceRequest(*request_params(type), &block)
      end
    end

    def card_request(type, &block)
      XmlBuilder.new(:header => HEADER) do |xml|
        xml.CardServiceRequest(*request_params(type), &block)
      end
    end

    def parse_xml(xml)
      raise OPI::Error, 'missing XML' unless xml

      begin
        Nokogiri::XML(xml)
      rescue Exception
        raise OPI::Error, 'invalid XML'
      end
    end

    # EPS response to the POS request for service; the possible results are identified by the required attribute
    # OverallResult (same as CardServiceResponse):
    #
    def parse_service_response(xml)
      doc = parse_xml(xml)
      node = doc&.css('ServiceResponse')&.first
      raise OPI::Error, 'invalid service response' unless node
      node.to_h.merge('success' => node.attr('OverallResult') == Result::Success)
    end

    def parse_card_response(xml)
      doc      = parse_xml(xml)
      node     = doc&.css('CardServiceResponse')&.first
      terminal = node&.css('Terminal')&.first
      tender   = node&.css('Tender')&.first
      amount   = tender&.css('TotalAmount')&.first
      auth     = tender&.css('Authorization')&.first

      raise OPI::Error, 'invalid card service response' unless node
      raise OPI::Error, 'invalid card service response (Terminal missing)' unless terminal

      node.to_h.merge(
        'success' => node.attr('OverallResult') == Result::Success,
        'amount' => amount&.text.to_f,
        'Terminal' => terminal.to_h,
        'Tender' => {
          'TotalAmount' => amount.to_h.merge(:text => amount&.text),
          'Authorization' => auth.to_h
        }
      )
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

    # In case of output to the printer, the absence of TextLine means that the printer has to be tested only to
    # know if it is ready to print so in a correct status). This test is always involving the flag Immediate as true.

    def parse_device_request(xml)
      raise OPI::Error, 'missing XML' unless xml

      begin
        doc = Nokogiri::XML(xml){ |conf| conf.noblanks }
      rescue Exception
        raise OPI::Error, 'invalid XML'
      end

      node = doc&.css('DeviceRequest')&.first
      raise OPI::Error, 'invalid device request' unless node
      #input = node&.css('Input')&.first   # only one input allowed
      output   = node&.css('Output') || [] # can have up to two outputs
      out = node.to_h
      #out['Input'] = input.to_s if input
      out['Output'] = output.map{|n|
        h = n.to_h
        h['device'] = n.attr('OutDeviceTarget')
        h['lines'] = n.children.map{|c|
          c.to_h.merge(:text=>c.text, :type=>c.name)
        }
        h
      }
      out
    end



    def format_device_response(request, response)
      XmlBuilder.new(:header => HEADER) do |xml|
        status = {
          'RequestType'=>request['RequestType'],
          'ApplicationSender'=>@application_id,  # Identifies the application sending the request.
          'WorkstationID'=>@workstation_id,      # Identifies the logical workstation (associated to the socket) receiving the response.
          #'POPID'                                # Necessary when Point Of Payment is not coincident with Workstation
          #'TerminalID'                          # Identifies the terminal/device proxy involved.
          'RequestID'=>request['RequestID'],     # ID of the request; for univocal referral Echo.
          #SequenceID                            # Used if one request is composed of multiple requests;
          #ReferenceRequestID,                   # Reference to a request: used in case of abort request.
          #'OverallResult'=>                     # result of the requested operation
        }
        xml.DeviceResponse(*status) do |xml|
          # can have up to 2 Output elements.
          if output
            xml.Output('OutDeviceTarget'=>'xx','OutResult'=>result)
          end
          # if input
          #   xml.Input #...
          # end
        end
      end
    end





    # POS logon to EPS application. Login operates per Workstation, independently from the
    # POPID.
    # Login does not imply any diagnostic process on the devices (processes to be triggered
    # explicitly through the Diagnosis).
    # A second login without a prior logoff is accepted every time (e.g. POS crashes).
    def login
      xml = service_request('Login') do |xml|
        xml.POSdata do |xml|
          xml.POSTimeStamp time_stamp
        end
      end
      parse_service_response(@connection.request(xml.to_s))['success']
    end

    # POS logoff from EPS application. Used to terminate operations with the POS or in case of
    # configuration, administration.
    # Logoff operates per Workstation, independently from the POPID.
    def logoff
      xml = service_request('Logoff') do |xml|
        xml.POSdata do |xml|
          xml.POSTimeStamp time_stamp
        end
      end
      parse_service_response(@connection.request(xml.to_s))['success']
    end

    def card_payment(amount, id = nil)
      raise OPI::Error, 'amount missing' unless amount

      amount = amount.to_f
      raise OPI::Error, 'amount must be > 0' unless amount > 0

      xml = card_request('CardPayment') do |xml|
        xml.POSdata do |xml|
          xml.POSTimeStamp time_stamp
          xml.TransactionNumber(id.to_s) if id
        end
        xml.TotalAmount('%.2f' % amount)
      end
      parse_card_response @connection.request(xml.to_s)
    end

    def reconcile; end

  end
end
