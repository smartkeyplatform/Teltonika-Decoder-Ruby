# Ruby and gems instalation
- Install rvm from `https://rvm.io/`
- Ruby 2.6.2
  ```
  rvm install "ruby-2.6.2"
  ```
- Required gems
  ```
  gem install color eventmachine awesome_print
  ```

# Running server
  ```
  ruby tests.rb
  ```
  First there will be codecs parse/create test
  Then server based on "event machine" starts listening on port 5555

# Simple server receive test under linux
```
echo -e -n "\x00\x00123456789123456\xFF\x00\x00\x00\x00\x00\x00\x00\x43\x08\x02\x00\x00\x01\x6B\x40\xD5\x7B\x48\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x01\x6B\x40\xD5\xC1\x98\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x01\x01\x01\x00\x00\x00\x02\x00\x00\x25\x2C\xFF\x00\x00\x00\x00\x00\x00\x00\x37\x0C\x01\x06\x00\x00\x00\x2F\x44\x49\x31\x3A\x31\x20\x44\x49\x32\x3A\x30\x20\x44\x49\x33\x3A\x30\x20\x41\x49\x4E\x31\x3A\x30\x20\x41\x49\x4E\x32\x3A\x31\x36\x39\x32\x34\x20\x44\x4F\x31\x3A\x30\x20\x44\x4F\x32\x3A\x31\x01\x00\x00\x66\xE3" > /dev/tcp/127.0.0.1/5555
```
Server should detect: 
- device with imei 123456789123456
- Codec8 packet
- Ping packet
- Codec12 packet

```
################################
running server on 5555
Device connected 12345678912345
detected codec: 8, size: 67
detected codec: 12, size: 55
[
    [0] #<FMB920::Codec8:0x0000561a74b7f720 @codec_id=8, @data_length=64, @data_to_read=0, @data=[2, 0, 0, 1, 107, 64, 213, 123, 72, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 107, 64, 213, 193, 152, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 2, 0, 0, 37, 44], @records=[#<FMB920::Codec8Data:0x0000561a74b7f478 @packet_length=32, @timestamp=1560160861000, @priority=1, @gps={:lng=>0, :lat=>0, :alt=>0, :angle=>0, :satellite=>0, :speed=>0}, @io={:event_io=>1, :total=>1, :raw=>[1, 1, 1, 1, 0, 0, 0, 0]}>, #<FMB920::Codec8Data:0x0000561a74b7ef78 @packet_length=32, @timestamp=1560160879000, @priority=1, @gps={:lng=>0, :lat=>0, :alt=>0, :angle=>0, :satellite=>0, :speed=>0}, @io={:event_io=>1, :total=>1, :raw=>[1, 1, 1, 1, 1, 0, 0, 0]}>], @status="ok", @response=[0, 0, 0, 2]>,
    [1] #<FMB920::CodecPing:0x0000561a74b7ea78 @codec_id=255>,
    [2] #<FMB920::Codec12:0x0000561a74b7e7d0 @codec_id=12, @packet_type="response", @length=55, @data_length=54, @data_to_read=0, @data=[1, 6, 0, 0, 0, 47, 68, 73, 49, 58, 49, 32, 68, 73, 50, 58, 48, 32, 68, 73, 51, 58, 48, 32, 65, 73, 78, 49, 58, 48, 32, 65, 73, 78, 50, 58, 49, 54, 57, 50, 52, 32, 68, 79, 49, 58, 48, 32, 68, 79, 50, 58, 49, 1, 0, 0, 102, 227], @records=["DI1:1 DI2:0 DI3:0 AIN1:0 AIN2:16924 DO1:0 DO2:1"], @status="ok", @response=[0, 0, 0, 1]>
]
connection to device 12345678912345 closed 
```

# Communication flow
  After connection device sends [0x00, 0x00] followed by imei. <br>
  Server responds with 0x01 if wants to talk with device, otherwise 0x00. <br>
  Now device will send Codec8 packets with GPS/IO data and answer for Codec12 Commands with Codec12 containing string response.

# Codecs
  Codec8/12 starts with preamble (4B of zeros) in case previous packet was malformed any data not being 4b of zeros is skipped (Excluding ping - 1B 255).


  ## Codec8
  Codec8 is used to send actual device status to server. It can contain multiple records which are accessible via 'records' property.<br>
  Requires acknowledgement which is auto generated as 'response' property. Ack data is table of records count encoded as bytes, eg. [0x00, 0x00, 0x00, 0x01] for one record

  ## Codec12
  Codec12 can encode command or response. 
  Same as Codec8 requires ack, but records count is constant (1) as there is only one command/response per packet.

  ## Ping
  Depending on configuration device can send it in fixed interval.
  Ping doesn't require any acknowledgement.

# Codecs classes
  Props:
  - status - pending (actualy processed packet), ok (packet fully received), fail (crc error)
  - records - data for codec8 (can be multiple, wrapped in Codec8Data class), or for codec 12 (single string in array)
  - response - set if ack is required (bytes to be sent)
  - codec_id - id of codec (8 - Codec8, 12 - Codec12, 255 - Ping)
  
  Methods:
  - Public
    - apply_data(bytes) - appends bytes to packet, returns not consumed bytes, when packet data is full triggers parsing
    - encoded_packet - only for Codec12 - creates byte encoded command for device
  - Private
    - parse_data - (for Codec8/Codec12) - called internally method which checks crc and parses bytes to records
    - create_ack - creates ack bytes from packets count

# IncomingPacketsParser
  Parser expects data in form of byte array. Can detect Codec8/12/Ping.

  Methods:
  - Public:
    - parse_data(data) - parses incoming data, detects codec type (or ping), creates right codec instance and applies bytes to it. When any packet (or ping) is ready returns array containing it, otherwise empty array. Wrong codec id raises exception.
  - Private:
    - append_initial_bytes - sets initial bytes containing size and codec id
    - reset_when_not_preamble - sets preamble (4B zero) resets buffer when preamble is wrong
    - parse_ping - parses ping

# Server
  Handles connection with device, sets imei then uses parser to process incoming data.
  Example command 'getgps' will be sent 10 seconds after connection

  Methods:
  - post_init - creates parser and initial_bytes array, sets timer to send test command (getgps)
  - receive_data(data) - receives data from socket, converts it to bytes array and passes to parse_incoming_data
  - parse_incoming_data(bytes) - depending on state sets imei of device or parses data to packets
  - initialize_connection(bytes) - sets initial bytes containing imei, sets it, responds with 0x01 (keep connection) to device
  - send_bytes(data) - converts bytes to format accepted by send_data
  - send_outcoming_command(command) - encodes string command and sends it to device
  - consume_packets(packets) - displays packets in console and sends acknowledgements
  - unbind - called when device closes conenction
