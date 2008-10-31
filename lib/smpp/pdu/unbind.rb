class Smpp::Pdu::Unbind < Smpp::Pdu::Base
  handles_cmd UNBIND

  def initialize(seq=next_sequence_number)
    super(UNBIND, 0, seq)
  end

  def self.from_wire_data(seq, status, body)
    new(seq)
  end
end
