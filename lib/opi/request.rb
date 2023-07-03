# frozen_string_literal: true

module OPI
  # perform requests to the server... format the request into
  # OPI protocol xml then send to the server using the connection.
  # parse the returned xml and extract key fields to use
  # as an appropriate return value.
  class Request

    HEADER = '<?xml version="1.0" encoding="UTF-8"?>'

    def initialize
      @workstation_id = 'pos1'
      @application_id = 'DemiPOS'
      @request_id     = 0
      @connection     = Connection.new
    end

    def next_id
      @request_id += 1
    end

    def time_stamp
      Time.now.xmlschema(3)
    end

    def request_params(type)
      [
        'RequestType' => type,
        'ApplicationSender' => @application_id,
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
      node.to_h.merge('success' => node.attr('OverallResult') == 'Success')
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
        'success' => node.attr('OverallResult') == 'Success',
        'amount' => amount&.text.to_f,
        'Terminal' => terminal.to_h,
        'Tender' => {
          'TotalAmount' => amount.to_h.merge(:text => amount&.text),
          'Authorization' => auth.to_h
        }
      )
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
