# frozen_string_literal: true

module FMB920
  class CodecPing < Codec
    CODEC_ID = 255

    def initialize
      @codec_id = CODEC_ID
    end
  end
end
