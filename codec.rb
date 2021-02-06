module FMB920
  class Codec
    attr_reader :status
    attr_reader :records

    def self.calculate_crc(data)
      crc = 0
      data.length.times do |offs|
        crc = crc ^ data[offs]
        8.times do # |bit|
          carry = crc & 1
          crc = crc >> 1
          crc = crc ^ 0xA001 if carry == 1
        end
      end
      crc
    end

    def self.val_from_bytes(data)
      val = 0
      (0..(data.size - 1)).each do |i|
        val *= 256
        val += data[i]
      end
      val
    end

    def self.place_in(dest,src,offset)
      src.length.times do |i|
        dest[offset+i]=src[i]
      end
    end

    def self.val_to_4_bytes(val)
      bytes = []
      4.times do
        bytes.push(val & 255)
        val = val >> 8
      end
      bytes.reverse
    end

    def self.string_to_bytes(str)
      str.chars().map(&:ord)
    end
  
    # applies data to bytes array
    def apply_data(bytes)
      bytes_to_append = [@data_to_read, bytes.length].min # calculate amount of bytes to be appended to data array
      @data += bytes[0..bytes_to_append]                  # add slice of data
      @data_to_read -= bytes_to_append                    # calculate remaining data to be read
      parse_data if @data_to_read.zero?                   # parse data to packets when all read
      bytes.slice(bytes_to_append, bytes.length)          # return array with unused bytes
    end

    def check_crc(crc_offset, crc_size, crc_start, crc_end, codec)
      expected_crc = Codec.val_from_bytes(@data.slice(crc_offset, crc_size)) # crc value from packet
      data_for_crc = @data[crc_start..(@data.length - 1 - crc_end)]          # data used to calculate new crc
      calculated_crc = Codec.calculate_crc([codec].concat(data_for_crc))     # first byte is codec id, then data array without last 4 bytes (expected crc)
      expected_crc == calculated_crc                                         # are all bytes same?
    end
  end
end