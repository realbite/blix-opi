require 'socket'
# the following connection types are supported:
#
#   CardServiceRequest / ServiceRequest from POS to EPS.  ( channel 0)
#   CardServiceResponse / ServiceResponse from EPS to POS. ( channel 0)
#   DeviceRequest from EPS to POS ( channel 1)
#   DeviceResponse from POS to EPS ( channel 1)

# The first TCP connection (Channel 0) – connecting from POS sight, listening from EPS sight -
# will be used for the CardService- and ServiceRequests from the POS to the EPS-Client.
# The CardServiceResponse or ServiceResponse from the EPS to the POS will be transmitted
# over the same TCP connection.
#
# The second TCP connection (Channel 1) – listening from POS sight, connecting from EPS sight
# - will be used for the DeviceRequests from the EPS-Client to the POS. The DeviceResponse
# from the POS to the EPS will be transmitted over the same TCP connection.

module OPI

  class Connection

    def initialize(opts={})
      @local_ip    = "127.0.0.1"  # the local ip
      @local_port  = 2000         # port to listen on ( channel 1) 4102
      @remote_ip   = "127.0.0.1"  # ip of EPS
      @remote_port = 2000         # port of EPS ( channel 0) 4100
      @timeout0    = 120       # time between a connect and the message
      @timeout1    = 330       # time between request and response
      @timeout2    = 300       # time between last message on channel0 or ..
                                #   channel1 and a message from EPS on channel1.
    end

    # make a connection to the EPS
    # A connection lives only as long as one Request / Response pair has processed or a Timeout has
    # occurred. The following sequence is valid for all connection types:
    #
    # timeout between request sent and response received.
    #
    # The XML messages starts with a 4 Byte long length indicator (big endian – network byte order).
    # It contains the length of the XML-Message. There is no Hex 0 at the end of the message
    # included.

    def request(msg)
      msg = msg.to_s
      startbytes = [msg.bytesize].pack('N')
      s = TCPSocket.open(@remote_ip, @remote_port)
      s.send(startbytes,0)
      s.send(msg,0)
      maxtime = Time.now + @timeout1
      startbytes = socket_timeout(s, maxtime, 4)
      len = startbytes.unpack('N')[0]
      socket_timeout(s, maxtime, len)
    ensure
      s.close
    end

    # listen for requests from the EPS
    # timeout between connection request and message received.
    def listen(&block)
      # It services only one client at a time.
      Socket.tcp_server_loop(@local_port) do |s, client_addrinfo|
        begin
          maxtime = Time.now + @timeout0
          startbytes = socket_timeout(s, maxtime, 4)
          len = startbytes.unpack('N')[0]
          msg = socket_timeout(s, maxtime, len)
          resp = block && block.call(msg)
          resp = resp.to_s
          startbytes = [resp.bytesize].pack('N')
          # the send can fail if the connection has timed out
          # at the other end.
          s.send(startbytes,0)
          s.send(resp,0)
        rescue Exception
            # just ignore the error for now.
        ensure
          s.close
        end
      end
    end

    # private

    def socket_timeout(sock, maxtime, maxlen)
      out = String.new
      loop do
        timeout = maxtime - Time.now
        raise TimeoutError if timeout <= 0
        if IO.select([sock],nil,nil,timeout)
          out += sock.recv_nonblock(maxlen)
        else
          raise TimeoutError
        end
        break if out.length >= maxlen
      end
      out
    end

  end # Connection
end
