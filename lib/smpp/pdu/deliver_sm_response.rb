class Smpp::Pdu::DeliverSmResponse < Smpp::Pdu::Base
  def initialize(seq, status=ESME_ROK)
    super(DELIVER_SM_RESP, status, seq, "\000") # body must be NULL..!
  end
end
