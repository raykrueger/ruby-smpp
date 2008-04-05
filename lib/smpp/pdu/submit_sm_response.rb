class Smpp::Pdu::SubmitSmResponse < Smpp::Pdu::Base
  attr_accessor :message_id
  def initialize(seq, status, message_id)
    message_id = message_id.chomp("\000")
    super(SUBMIT_SM_RESP, status, seq, message_id)
    @message_id = message_id
  end
end    
