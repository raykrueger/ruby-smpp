class Smpp::Pdu::BindTransceiverResponse < Smpp::Pdu::Base
  attr_accessor :system_id
  def initialize(seq, status, system_id)
    super(BIND_TRANSCEIVER_RESP, status, seq, system_id) # pass in system_id as body for simple debugging
    @system_id = system_id
  end
end
