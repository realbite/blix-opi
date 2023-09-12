# frozen_string_literal: true
module OPI
  # handle the parsing and formatting of xml requests and responses.

  class Protocol

    HEADER = '<?xml version="1.0" encoding="UTF-8"?>'

    def initialize(options={})
      @workstation_id = options[:workstation_id] || 'WORKSTATION'
      @application_id = options[:application_id] || 'POS'
      @request_prefix = Time.now.to_i
      @request_id     = 0
    end

    def next_id
      @request_id += 1
      "#{@request_prefix}_#{@request_id}"
    end

    def request_params(type)
      [
        'RequestType' => type,
        'ApplicationSender' => @application_id, # Identifies the application sending the request.
        'WorkstationID' =>@workstation_id,
        'RequestID' => next_id
      ]
    end

    def service_request_xml(type, &block)
      XmlBuilder.new(:header => HEADER) do |xml|
        xml.ServiceRequest(*request_params(type), &block)
      end
    end

    def card_request_xml(type, &block)
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

    def service_response_xml(info, status, &block)
      XmlBuilder.new(:header => HEADER) do |xml|
        attributes = {
          'RequestType'=>info['RequestType'],
          'ApplicationSender'=>@application_id,  # Identifies the application sending the request.
          'WorkstationID'=>@workstation_id,      # Identifies the logical workstation (associated to the socket) receiving the response.
          'RequestID'=>info['RequestID'],        # ID of the request; for univocal referral Echo.
          'OverallResult'=>status,               # result of the requested operation
        }
        # ReferenceRequestID,                   # Reference to a request: used in case of abort request.
        status['TerminalID'] = info['TerminalID'] if info['TerminalID'] # Identifies the terminal/device proxy involved.
        status['SequenceID'] = info['SequenceID'] if info['SequenceID'] # Used if one request is composed of multiple requests;
        status['POPID'] = info['POPID']           if info['POPID']      # Necessary when Point Of Payment is not coincident with Workstation
        xml.ServiceResponse(attributes, &block)
      end
    end

    def card_response_xml(info, status, &block)
      XmlBuilder.new(:header => HEADER) do |xml|
        attributes = {
          'RequestType'=>info['RequestType'],
          'ApplicationSender'=>@application_id,  # Identifies the application sending the request.
          'WorkstationID'=>@workstation_id,      # Identifies the logical workstation (associated to the socket) receiving the response.
          'RequestID'=>info['RequestID'],        # ID of the request; for univocal referral Echo.
          'OverallResult'=>status,               # result of the requested operation
        }
        # ReferenceRequestID,                   # Reference to a request: used in case of abort request.
        status['TerminalID'] = info['TerminalID'] if info['TerminalID'] # Identifies the terminal/device proxy involved.
        status['SequenceID'] = info['SequenceID'] if info['SequenceID'] # Used if one request is composed of multiple requests;
        status['POPID'] = info['POPID']           if info['POPID']      # Necessary when Point Of Payment is not coincident with Workstation
        xml.CardServiceResponse(attributes, &block)
      end
    end

    def device_response_xml(info, status, &block)
      XmlBuilder.new(:header => HEADER) do |xml|
        attributes = {
          'RequestType'=>info['RequestType'],
          'ApplicationSender'=>@application_id,  # Identifies the application sending the request.
          'WorkstationID'=>@workstation_id,      # Identifies the logical workstation (associated to the socket) receiving the response.
          'RequestID'=>info['RequestID'],        # ID of the request; for univocal referral Echo.
          'OverallResult'=>status,               # result of the requested operation
        }
        # ReferenceRequestID,                   # Reference to a request: used in case of abort request.
        status['TerminalID'] = info['TerminalID'] if info['TerminalID'] # Identifies the terminal/device proxy involved.
        status['SequenceID'] = info['SequenceID'] if info['SequenceID'] # Used if one request is composed of multiple requests;
        status['POPID'] = info['POPID']           if info['POPID']      # Necessary when Point Of Payment is not coincident with Workstation
        xml.DeviceResponse(attributes, &block)
      end
    end

  end
end
