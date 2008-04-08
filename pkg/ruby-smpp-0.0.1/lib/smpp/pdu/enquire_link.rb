class Smpp::Pdu::EnquireLink < Smpp::Pdu::Base
  def initialize(seq = next_sequence_number)
    super(ENQUIRE_LINK, 0, seq)
  end
end
