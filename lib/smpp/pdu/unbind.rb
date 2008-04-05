class Smpp::Pdu::Unbind < Smpp::Pdu::Base
  def initialize(seq=next_sequence_number)
    super(UNBIND, 0, seq)
  end
end
