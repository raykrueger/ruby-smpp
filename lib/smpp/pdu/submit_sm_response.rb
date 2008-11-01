class Smpp::Pdu::SubmitSmResponse < Smpp::Pdu::Base
  handles_cmd SUBMIT_SM_RESP

  attr_accessor :message_id

  def initialize(seq, status, message_id)
    seq ||= next_sequence_number
    body = message_id.to_s + "\000"
    super(SUBMIT_SM_RESP, status, seq, body)
    @message_id = message_id
  end

  def self.from_wire_data(seq, status, body)
    message_id = body.chomp("\000")
    new(seq, status, message_id)
  end
end    
