module FMB920
  class Codec12 < Codec
    attr_reader :encoded_packet

    FB_CMD_RSP_QUANTITY_1 = 0
    FB_TYPE = 1
    FB_CONTENT_LENGTH = 2
    FB_CONTENT = 6
    FE_CMD_RSP_QUANTITY_2 = 4
    FE_CRC = 0

    SIZE_CMD_RSP_QUANTITY_1 = 1
    SIZE_TYPE = 1
    SIZE_CONTENT_LENGTH = 4
    SIZE_CMD_RSP_QUANTITY_2 = 1
    SIZE_CRC = 4

    CRC_CALC_BEGIN_OFFSET = 0
    CRC_CALC_END_OFFSET = 4
    CODEC_ID = 12

    # for bytes generation
    PACKET_SIZE_CONSTANT = 20
    PACKET_CONTENT_SIZE_IGNORED_BYTES = 12
    PACKET_OFFSET = 9
    PACKET_CODEC_OFFSET = 8
    PACKET_LENGTH_OFFSET = 4
    PACKET_CMD_QUANT_OFFSET = 9
    PACKET_TYPE_COMMAND = 5
    PACKET_CRC_START_OFFS = 8
    PACKET_CRC_STOP_OFFS = 4

    def initialize(packet_type, length=0, payload="") # size 0 for command as it will be calculated
      @codec_id=CODEC_ID
      @packet_type = packet_type
      @length = length

      case @packet_type
      when 'response'
        @data_length = length - 1                # codec id not included here - skip 1 byte
        @data_to_read = @data_length + SIZE_CRC  # size from "number of data 1" to crc
        @data = []                               # binary data
        # @records = []                            # parsed records
      when 'command'
        @payload = payload
      end

      @records = []                            # parsed records
      @status = 'pending'                      # status of packet
    end

    def parse_data
      crc_offset = @data.length - FE_CRC - SIZE_CRC
      return @status = 'fail' unless check_crc(crc_offset, SIZE_CRC, CRC_CALC_BEGIN_OFFSET, CRC_CALC_END_OFFSET, CODEC_ID)
      # quantity is ignored in codec12, only one record
      record_size = Codec.val_from_bytes(@data.slice(FB_CONTENT_LENGTH, SIZE_CONTENT_LENGTH))  # calculate record size (should be same)
      record_string = @data.slice(FB_CONTENT, record_size).pack('c*') # record data parsed as string
      @records.push(record_string)                                      # add to record list 
      create_ack(1) # record count always 1
      @status = 'ok' # all done, set status to ok
    end

    def encoded_packet
      data_size = PACKET_SIZE_CONSTANT + @payload.length   # size
      encoded = Array.new(data_size, 0)                    # array for encoded packet

      packet_data_size = Codec.val_to_4_bytes(data_size-PACKET_CONTENT_SIZE_IGNORED_BYTES)
      Codec.place_in(encoded, packet_data_size, PACKET_LENGTH_OFFSET)  # place size of packet data
      
      encoded[PACKET_CODEC_OFFSET] = CODEC_ID                          # place codec id
      encoded[PACKET_OFFSET + FB_CMD_RSP_QUANTITY_1] = 1               # count is always 1 for Codec12
      encoded[PACKET_OFFSET + FB_TYPE] = PACKET_TYPE_COMMAND           # set packet type "command"
      Codec.place_in(encoded, Codec.val_to_4_bytes(@payload.length), PACKET_OFFSET + FB_CONTENT_LENGTH) # set command length
      Codec.place_in(encoded, Codec.string_to_bytes(@payload), PACKET_OFFSET + FB_CONTENT)              # place encoded command
      encoded[encoded.length - 1 - FE_CMD_RSP_QUANTITY_2] = 1                            # count is always 1 for Codec12

      crc_offset = encoded.length - FE_CRC - SIZE_CRC # calculate offset to place crc checksum
      crc_data = encoded[PACKET_CRC_START_OFFS .. encoded.length - 1 -PACKET_CRC_STOP_OFFS] # data for calculation
      crc = Codec.calculate_crc(crc_data) # calculate crc
      Codec.place_in(encoded, Codec.val_to_4_bytes(crc), crc_offset) # place crc

      encoded
    end
  end
end