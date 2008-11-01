class Smpp::Pdu::EnquireLinkResponse < Smpp::Pdu::Base
  handles_cmd ENQUIRE_LINK_RESP

  def initialize(seq = next_sequence_number)
    super(ENQUIRE_LINK_RESP, ESME_ROK, seq)
  end

  def self.from_wire_data(seq, status, body)
    new(seq)
  end
end
