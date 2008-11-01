class Smpp::Pdu::EnquireLink < Smpp::Pdu::Base
  handles_cmd ENQUIRE_LINK

  def initialize(seq = next_sequence_number)
    super(ENQUIRE_LINK, 0, seq)
  end

  def self.from_wire_data(seq, status, body)
    new(seq)
  end
end
