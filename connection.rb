require 'eventmachine'

module FMB920
  class Server < EventMachine::Connection
    attr_reader :imei
    attr_reader :status

    HEADER_SIZE = 16
    IMEI_START = 2
    IMEI_END = 16
    RESPONSE_OK = [1]
    RESPONSE_ERR = [0]


    def post_init
      @parser = IncomingPacketsParser.new
      @status = "init"
      @initial_bytes = []
    end

    def receive_data data
      # puts data
      # puts data.length
      parse_incoming_data(data.unpack('C*'))
    end

    def parse_incoming_data(data)
      case @status
      when 'init'
        data = initialize_connection(data)
        parse_incoming_data(data) if data.length.positive?  # if not all packets consumed do recursive call to parse as packets
      when 'ready'
        packets = @parser.parse_data(data)
        consume_packets(packets)
      end
    end

    def initialize_connection(data)
      if @initial_bytes.length < HEADER_SIZE
        bytes_to_append = [HEADER_SIZE - @initial_bytes.length, data.length].min # calculate amount of bytes to be appended to data array
        @initial_bytes += data.slice(0,bytes_to_append)                          # add slice of data
        data = data.slice(bytes_to_append, data.length)                         # return array with unused bytes
      end

      if @initial_bytes.length == HEADER_SIZE
        @imei = @initial_bytes[IMEI_START..IMEI_END].pack('C*')
        send_bytes RESPONSE_OK # ack imei accepted
        @status = "ready"
      end
      data
    end

    def send_bytes(data) # wraps send_data to accept byte array
      send_data data.pack('C*')
    end

    def send_outcoming_command(command)
      data = Codec12.new('command',0,command).encoded_packet
      send_bytes(data)
    end

    def consume_packets(packets)
      packets.each do |packet|
        send_bytes(packet.response) if packet.response # send acks
      end
      ap packets # just display them
    end

    # connection closed
    def unbind(reason="")
      puts "connection to device #{@imei} closed #{reason}"
    end
  end

  class Machine
    def initialize
      EventMachine::run {
        @server = EventMachine::start_server "localhost", 5555, Server
        EventMachine.add_timer 5, proc { puts "Executing timer event: #{@server.inspect}" }
        puts 'running server on 5555'
      }
    end
  end

end