require 'awesome_print'
require 'color'
require 'byebug'
require_relative 'incoming_packets_parser'
require_relative 'codec.rb'
require_relative 'codec_ping.rb'
require_relative 'codec_8.rb'
require_relative 'codec_12.rb'

TEST_STR_8 = 'FF000000000000004308020000016B40D57B480100000000000000000000000000000001010101000000000000016B40D5C198010000000000000000000000000000000101010101000000020000252C'
TEST_STR_12_RESP = 'FF00000000000000370C01060000002F4449313A31204449323A30204449333A302041494E313A302041494E323A313639323420444F313A3020444F323A3101000066E3'
TEST_STR_12_CMD = '000000000000000F0C010500000007676574696E666F0100004312'


def str_to_hex(str)
  str.scan(/../).map(&:hex)
end

puts "\n"
puts "\n"
@parser = FMB920::IncomingPacketsParser.new

puts '='*16
puts 'CODEC 8'
puts 'data:'

puts str_to_hex(TEST_STR_8+TEST_STR_8).inspect
puts ''
ap @parser.parse_data(str_to_hex(TEST_STR_8+TEST_STR_8))
#byebug

puts '='*16
puts 'CODEC 12 RESPONSE'
puts 'data:'

puts str_to_hex(TEST_STR_12_RESP+TEST_STR_12_RESP).inspect
puts ''
puts @parser.parse_data(str_to_hex(TEST_STR_12_RESP+TEST_STR_12_RESP)).inspect

puts '='*16
puts 'CODEC 12 COMMAND GENERATION'
puts 'expected data:'

puts str_to_hex(TEST_STR_12_CMD).inspect
puts ''
puts 'generated data:'
@packet = FMB920::Codec12.new('command', 0, 'getinfo')
puts @packet.encoded_packet.inspect
puts @packet.encoded_packet == str_to_hex(TEST_STR_12_CMD) ? "Command ok" : "Command is wrong"