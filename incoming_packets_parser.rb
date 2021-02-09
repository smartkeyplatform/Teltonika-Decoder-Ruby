# frozen_string_literal: true

#
# Possible packets for FMB920: C8, C12, PING(requires response to device)
#

module FMB920
  class IncomingPacketsParser
    CODEC_8 = 8
    CODEC_12 = 12
    CODEC_PING = 255
    # FB - from begining
    FB_LENGTH = 4
    FB_CODEC = 8
    SIZE_LENGTH = 4
    SIZE_CODEC = 1
    SIZE_ZEROS = 4
    HEAD_LENGTH = SIZE_ZEROS + SIZE_CODEC + SIZE_LENGTH

    def initialize
      @buffer = []         # buffer for incoming data
      @actual_packet = nil # packet in progress
    end

    def parse_data(data)
      packets = []

      if @buffer.empty?
        data, ping_packet = parse_ping(data) # ping is one byte 0xFF
      end
      packets += ping_packet

      # every packet (without ping) starts with 4B zeros
      data = reset_when_not_preamble(data) if @buffer.length < SIZE_ZEROS

      # bytes containing size and codec id
      data = append_initial_bytes(data) if @buffer.length < HEAD_LENGTH

      # if can create new packet with buffered data (length+codec)
      if @actual_packet.nil? && HEAD_LENGTH == @buffer.length
        codec = @buffer[FB_CODEC]                                          # get codec id
        size = Codec.val_from_bytes(@buffer.slice(FB_LENGTH, SIZE_LENGTH)) # get data length
        puts "detected codec: #{codec}, size: #{size}"
        case codec
        when CODEC_8
          @actual_packet = Codec8.new(size)
        when CODEC_12
          @actual_packet = Codec12.new('response', size)
        else
          raise("Codec #{codec} not implemented, malformed packet?") # break connection
        end
      end
      data = @actual_packet.apply_data(data) if @actual_packet

      # if there is a packet with status 'ok' or 'fail'
      if @actual_packet && @actual_packet.status != 'pending'
        packets.push(@actual_packet)  # push actual packet
        @actual_packet = nil          # reset packet variable
        @buffer = []                  # reset buffer, remaining data will be discarded until preamble
      end

      # run parse on rest of data when any left
      return packets + parse_data(data) if data.length.positive?

      packets # or just return actual packets
    end

    private

    # appends initial bytes (after preamble) with data size and codec id
    def append_initial_bytes(data)
      bytes_to_append = [data.length, HEAD_LENGTH - @buffer.length].min
      @buffer += data.slice(0, bytes_to_append)
      data.slice(bytes_to_append, data.length) # return remaining data
    end

    # eg in case last packet was malformed skip until preamble (4B of zeros)
    def reset_when_not_preamble(data)
      offset = 0
      # while buffer is not containing 4B zeros or offset is outside data range
      while @buffer.length < SIZE_ZEROS && offset < data.length
        if data[offset].zero? # if it was zero
          @buffer.push(0)     # push zero to buffer
        else
          @buffer = [] # reset buffer
        end
        offset += 1
      end
      data.slice(offset, data.size) # return remaining data
    end

    def parse_ping(data)
      return data, [] if data[0] != 0xFF # not a ping (0xff)

      [data.slice(1, data.length), [CodecPing.new]]
    end
  end
end
