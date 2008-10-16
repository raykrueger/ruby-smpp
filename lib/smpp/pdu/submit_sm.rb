# Sending an MT message
class Smpp::Pdu::SubmitSm < Smpp::Pdu::Base
  attr_accessor :source_addr, :destination_addr, :short_message, :source_addr, :esm_class, :msg_reference, :stat
  # Note: short_message (the SMS body) must be in iso-8859-1 format
  def initialize(source_addr, destination_addr, short_message, options={}, seq = nil, status = nil, body = nil)
    @msg_body = short_message
    if body.blank?
      # generate a body given the individual params
      body = Smpp::Pdu::Base.build_sm_body(source_addr, destination_addr, short_message, options)
      seq = next_sequence_number
    else
      # otherwise unpack the given body into the params
      # brutally unpack it
      service_type, 
      source_addr_ton, 
      source_addr_npi, 
      @source_addr, 
      dest_addr_ton, 
      dest_addr_npi, 
      @destination_addr, 
      @esm_class, 
      protocol_id,
      priority_flag, 
      schedule_delivery_time, 
      validity_period, 
      registered_delivery, 
      replace_if_present_flag, 
      data_coding, 
      sm_default_msg_id,
      sm_length, 
      @msg_body = body.unpack('Z*CCZ*CCZ*CCCZ*Z*CCCCCa*')
    end
    super(SUBMIT_SM, 0, seq, body)        
  end
  
  # some special formatting is needed for SubmitSm PDUs to show the actual message content
  def to_human
    # convert header (4 bytes) to array of 4-byte ints
    a = @data.to_s.unpack('N4')       
    sprintf("(%22s) len=%3d cmd=%8s status=%1d seq=%03d (%s)", self.class.to_s[11..-1], a[0], a[1].to_s(16), a[2], a[3], @msg_body[0..30])
  end
end
