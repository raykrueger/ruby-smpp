class Smpp::OptionalParameter

  attr_reader :tag, :value
  
  def initialize(tag, value)
    @tag = tag
    @value = value
  end

  def [](symbol)
    self.send symbol
  end

  def to_s
    self.inspect
  end

  #class methods
  class << self
    def from_wire_data(data)

      return nil if data.nil?
      tag, length, remaining_bytes = data.unpack('H4na*')
      tag = tag.hex

      raise "invalid data, cannot parse optional parameters" if tag == 0 or length.nil?

      value = remaining_bytes.slice!(0...length)

      return new(tag, value), remaining_bytes
    end

  end

end
