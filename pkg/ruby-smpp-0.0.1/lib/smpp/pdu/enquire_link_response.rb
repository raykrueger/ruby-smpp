class Smpp::Pdu::EnquireLinkResponse < Smpp::Pdu::Base
  def initialize(seq)
    super(ENQUIRE_LINK_RESP, ESME_ROK, seq)
  end
end
