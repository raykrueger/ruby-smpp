class Smpp::Pdu::DeliverSmResponse < Smpp::Pdu::Base
  handles_cmd DELIVER_SM_RESP

  def initialize(seq, status=ESME_ROK)
    seq ||= next_sequence_number
    super(DELIVER_SM_RESP, status, seq, "\000") # body must be NULL..!
  end

  def self.from_wire_data(seq, status, body)
    new(seq, status)
  end
end
