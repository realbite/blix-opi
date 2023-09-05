require 'logger'

module OPI
  class Terminal

    attr_reader :opts

    DEFAULT_OPTS = {
         :local_host=>'localhost',
         :local_port=>4102,            # port to listen on
         :remote_host=>'localhost',    # terminal ip
         :remote_port=> 4100,          # terminal port
         :timeout_0 =>120,             # timeout between a connect and message
         :timeout_1 =>330,             # timeout between request and response
         :timeout_2 =>300              # timeout between any messages with terminal
    }

    def initialize(opts={})
      @opts = DEFAULT_OPTS.merge(opts)
      # raise ArgumentError, "workstation_id required" unless opts[:workstation_id]
      # raise ArgumentError, "application_id required" unless opts[:application_id]
      @opts[:logger] ||= Logger.new(STDOUT)
      @connection = opts[:connection] || Connection.new(@opts)
      @parser     = Protocol.new
      @devices = {}
    end

    # register a device and the handler to process requests.
    def register_device(name, handler)
      raise ArgumentError,"invalid name"    unless name.kind_of?(String)
      raise ArgumentError,"invalid handler" unless handler.kind_of?(Handler)
      @devices[name] = handler
    end

    # listen on the connection for device requests.
    def listen
      @connection.listen do |xml|
        handle_device_request(xml)
      end
    end

    # run device handlers and return the overall status
    def process_device_outputs(outputs)
      outputs.map do |out|
        device  = out['device']
        continue Result::ValidationError unless device
        handler =  @devices[device]
        if handler && handler.respond_to?(:output)
          # pass the details to the handler
          begin
            handler.output(out)
          rescue Exception=>e
            Result::Failure
          end
        else
          # return not handled response.
          Result::DeviceUnavailable
        end
      end
    end

    def calculate_overall_status(status_list)
      # choose the best return status
      if status_list.length == 0
        Result::Failure
      elsif status_list.length == 2
        if (status_list[0] == Result::Success) && (status_list[1] == Result::Success)
          Result::Success
        else
          Result::Failure
        end
      else
        status_list[0]
      end
    end

    # pass the device request to the relevant handler.
    # only handles Output for now.
    def handle_device_request(xml)
      info = @parser.parse_device_request(xml)
      type    = info['RequestType']
      id      = info['RequestID']
      outputs = info['Output'] || []
      outputs = outputs[0..1]  # max length = 2
      status_list = []
      status = if type && id
        status_list = process_device_outputs(outputs)
        calculate_overall_status(status_list)
      else
        Result::ValidationError
      end

      # now respond to the payment terminal
      @parser.device_response_xml(info, status) do |xml|
        outputs.each_with_index do |out, idx|
          xml.Output('OutDeviceTarget'=>out['device'],'OutResult'=>status_list[idx])
        end
      end
    end

    # POS logon to EPS application. Login operates per Workstation, independently from the
    # POPID.
    # Login does not imply any diagnostic process on the devices (processes to be triggered
    # explicitly through the Diagnosis).
    # A second login without a prior logoff is accepted every time (e.g. POS crashes).
    def login
      xml = @parser.service_request_xml('Login') do |xml|
        xml.POSdata do |xml|
          xml.POSTimeStamp time_stamp
        end
      end
      @parser.parse_service_response(@connection.request(xml.to_s))['success']
    end

    # POS logoff from EPS application. Used to terminate operations with the POS or in case of
    # configuration, administration.
    # Logoff operates per Workstation, independently from the POPID.
    def logoff
      xml = @parser.service_request_xml('Logoff') do |xml|
        xml.POSdata do |xml|
          xml.POSTimeStamp time_stamp
        end
      end
      @parser.parse_service_response(@connection.request(xml.to_s))['success']
    end

    # returns a hash of information regarding the payment.
    # the terminal can call device requests while the payment is being performed.
    def card_payment(amount, id = nil)
      raise OPI::Error, 'amount missing' unless amount

      amount = amount.to_f
      raise OPI::Error, 'amount must be > 0' unless amount > 0

      xml = @parser.card_request_xml('CardPayment') do |xml|
        xml.POSdata do |xml|
          xml.POSTimeStamp time_stamp
          xml.TransactionNumber(id.to_s) if id
        end
        xml.TotalAmount('%.2f' % amount)
      end
      @parser.parse_card_response @connection.request(xml.to_s)
    end

    def reconcile; end

    def time_stamp
      Time.now.xmlschema(3)
    end

  end
end
