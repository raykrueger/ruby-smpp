class Smpp::Pdu::UnbindResponse < Smpp::Pdu::Base
  handles_cmd UNBIND_RESP

  def initialize(seq, status)
    seq ||= next_sequence_number
    super(UNBIND_RESP, status, seq)
  end

  def self.from_wire_data(seq, status, body)
    new(seq, status)
  end
end
