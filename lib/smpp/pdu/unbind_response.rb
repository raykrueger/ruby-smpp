class Smpp::Pdu::UnbindResponse < Smpp::Pdu::Base
  def initialize(seq, status)
    super(UNBIND_RESP, status, seq)
  end
end
