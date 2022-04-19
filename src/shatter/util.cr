require "json"

module Shatter
  def self.hex(int : Int) : String
    (int.to_s 16).rjust 2, '0'
  end

  def self.pad(message : Bytes, pad_length : Int) : Bytes
    pad_block_len = pad_length - message.size - 3
    raise Exception.new("Maximum message size is #{pad_length - 11}") if pad_block_len < 8
    output = Bytes.new pad_length
    output[0] = 0_u8
    output[1] = 1_u8
    pad_block_len.times do |i|
      output[i + 2] = 0xFF_u8
    end
    output[pad_block_len + 2] = 0_u8
    message.copy_to output[pad_block_len + 3, message.size]
    output
  end
end

struct Enum
  def to_json_object_key : String
    to_s
  end
end
