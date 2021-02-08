# frozen_string_literal: true

module FMB920
  class Codec8 < Codec
    # FB - from beginning (number of data 1) # FE - from end of packet
    FB_NUMBER_OF_DATA_1 = 0
    FB_FIRST_RECORD_OFFSET = 1
    FE_CRC = 0
    FE_NUMBER_OF_DATA_2 = 4
    # sizes
    SIZE_NUMBER_OF_DATA = 1
    SIZE_CRC = 4

    CRC_CALC_BEGIN_OFFSET = 0
    CRC_CALC_END_OFFSET = 4
    CODEC_ID = 8

    # packet status? [pending,ok,fail]

    def initialize(length)
      @codec_id=CODEC_ID
      @data_length = length - 1 - SIZE_NUMBER_OF_DATA * 2  # codec id not included here - skip 1 byte
      @data_to_read = length - 1 + SIZE_CRC  # size from "number of data 1" to crc (without codec id - skip 1 byte)
      @data = []                               # binary data
      @records = []                            # parsed records
      @status = 'pending'                      # status of packet
    end

    private
      # parses records if crc is ok
      def parse_data
        # if crc is wrong treat packet as wrong, device will attempt to retransmit it
        crc_offset = @data.length - FE_CRC - SIZE_CRC
        return @status = 'fail' unless check_crc(crc_offset, SIZE_CRC, CRC_CALC_BEGIN_OFFSET, CRC_CALC_END_OFFSET, CODEC_ID)

        records_count = @data[FB_NUMBER_OF_DATA_1]  # get number of records
        record_size = @data_length / records_count  # calculate record size
        record_offset = FB_FIRST_RECORD_OFFSET      # set offset to start processing records
        while record_offset < @data_length + FB_FIRST_RECORD_OFFSET                # while there is enough data
          r = Codec8Data.new(record_size, @data.slice(record_offset, record_size)) # create new record
          @records.push(r)                # add to records list 
          record_offset += record_size    # change offset to next record
        end
        create_ack(records_count) # creates acknowledgement for packet
        @status = 'ok' # all done, set status to ok
      end

      
  end

  # codec 8 can have multiple data records in it
  class Codec8Data
    # FB - from beginning (number of data 1) # FE - from end of packet
    FB_TIMESTAMP = 0
    FB_PRIORITY = 8
    FB_GPS = 9
    FB_IO = 24
    SIZE_TIMESTAMP = 8
    #SIZE_PRIORITY = 1
    SIZE_GPS = 15
    # SIZE_IO=?

    GPS_LNG = 0
    GPS_LNG_SIZE = 4
    GPS_LAT = GPS_LNG_SIZE
    GPS_LAT_SIZE = 4
    GPS_ALT = GPS_LAT + GPS_LAT_SIZE
    GPS_ALT_SIZE = 2
    GPS_ANGLE = GPS_ALT + GPS_ALT_SIZE
    GPS_ANGLE_SIZE = 2
    GPS_SATELLITE = GPS_ANGLE + GPS_ANGLE_SIZE
    GPS_SATELLITE_SIZE = 1
    GPS_SPEED = GPS_SATELLITE + GPS_SATELLITE_SIZE
    GPS_SPEED_SIZE = 2

    EVENT_IO_ID = 0
    EVENT_IO_ID_SIZE = 1
    IO_NO = EVENT_IO_ID_SIZE
    IO_NO_SIZE = 1


    def initialize(length, bytes)
      @packet_length = length
      apply_data(bytes)
    end

    private
      def apply_data(bytes)
        @timestamp = bytes.slice(FB_TIMESTAMP, SIZE_TIMESTAMP)
        @priority = bytes[FB_PRIORITY]
        @gps = parse_gps(bytes.slice(FB_GPS, SIZE_GPS))
        @io = parse_io(bytes[FB_IO..bytes.length - 1])
      end

      def parse_gps(data)
        {
          lng: Codec.val_from_bytes(data.slice(GPS_LNG, GPS_LNG_SIZE)),
          lat: Codec.val_from_bytes(data.slice(GPS_LAT, GPS_LAT_SIZE)),
          alt: Codec.val_from_bytes(data.slice(GPS_ALT, GPS_ALT_SIZE)),
          angle: Codec.val_from_bytes(data.slice(GPS_ANGLE, GPS_ANGLE_SIZE)),
          satellite: Codec.val_from_bytes(data.slice(GPS_SATELLITE, GPS_SATELLITE_SIZE)),
          speed: Codec.val_from_bytes(data.slice(GPS_SPEED, GPS_SPEED_SIZE))
        }
      end

      def parse_io(data)
        io = {
          event_io: Codec.val_from_bytes(data.slice(EVENT_IO_ID, EVENT_IO_ID_SIZE)),
          total: Codec.val_from_bytes(data.slice(IO_NO, IO_NO_SIZE)),
          raw: data
        }

        
        # # io values
        # offset = EVENT_IO_ID_SIZE + IO_NO_SIZE
        # io.total.times do |v|

        # end
        
      end

  end
end
