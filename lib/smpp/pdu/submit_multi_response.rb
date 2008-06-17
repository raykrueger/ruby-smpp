# Recieving response for an MT message sent to multiple addresses
# Author: Abhishek Parolkar, (abhishek[at]parolkar.com)
class Smpp::Pdu::SubmitMultiResponse < Smpp::Pdu::Base
  attr_accessor :message_id
  def initialize(seq, status, message_id)
    message_id = message_id.chomp("\000")
    super(SUBMIT_MULTI_RESP, status, seq, message_id)
    @message_id = message_id
  end
end    
