require 'logger'

module OPI
  class Terminal

    attr_reader :opts

    DEFAULT_OPTS = {
         :local_host=>'localhost',
         :local_port=>4102,            # port to listen on
         :remote_host=>'localhost',    # terminal ip
         :remote_post=> 4100,          # terminal port
         :timeout_0 =>120,             # timeout between a connect and message
         :timeout_1 =>330,             # timeout between request and response
         :timeout_2 =>300              # timeout between any messages with terminal
    }

    def initialize(opts={})
      @opts = DEFAULT_OPTS.merge(opts)
      raise ArgumentError, "workstation_id required" unless opts[:workstation_id]
      raise ArgumentError, "application_id required" unless opts[:application_id]
      @opts[:logger] ||= Logger.new(STDOUT)
      @connection = Connection.new(@opts)
      @protocol   = Protocol.new(@connection, @opts)
      @devices = {}
    end

    # register a device and the handler to process requests.
    def register_device(name, handler)
      raise ArgumentError,"invalid name"    unless name.kind_of?(String)
      raise ArgumentError,"invalid handler" unless handler.kind_of?(Handler)
      @devices[name] = handler
    end

    def listen

    end

    def login
      @protocol.login
    end

    def logoff
      @protocol.logoff
    end

    def card_payment(*args)
      @protocol.card_payment(*args)
    end

  end
end
