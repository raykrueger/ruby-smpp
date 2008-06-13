# Sending an MT message
class Smpp::Pdu::SubmitSm < Smpp::Pdu::Base
  
  # Note: short_message (the SMS body) must be in iso-8859-1 format
  def initialize(source_addr, destination_addr, short_message, options={})
    options.merge!(
      :esm_class => 0,    # default smsc mode
      :dcs => 3           # iso-8859-1
    ) { |key, old_val, new_val| old_val } 
  
    @msg_body = short_message
    
    udh = options[:udh]          
    service_type            = ''
    source_addr_ton         = 0 # network specific
    source_addr_npi         = 1 # unknown
    dest_addr_ton           = 1 # international
    dest_addr_npi           = 1 # unknown 
    esm_class               = options[:esm_class]
    protocol_id             = 0
    priority_flag           = 1
    schedule_delivery_time  = ''
    validity_period         = ''
    registered_delivery     = 1 # we want delivery notifications
    replace_if_present_flag = 0
    data_coding             = options[:dcs]
    sm_default_msg_id       = 0
    payload                 = udh ? udh + short_message : short_message # this used to be (short_message + "\0") which caused SMSCs to translate "\0" --> "@"
    sm_length               = payload.length
    
    # craft the string/byte buffer
    pdu_body = sprintf("%s\0%c%c%s\0%c%c%s\0%c%c%c%s\0%s\0%c%c%c%c%c%s", service_type, source_addr_ton, source_addr_npi, source_addr,
    dest_addr_ton, dest_addr_npi, destination_addr, esm_class, protocol_id, priority_flag, schedule_delivery_time, validity_period,
    registered_delivery, replace_if_present_flag, data_coding, sm_default_msg_id, sm_length, payload)
    super(SUBMIT_SM, 0, next_sequence_number, pdu_body)        
  end
  
  # some special formatting is needed for SubmitSm PDUs to show the actual message content
  def to_human
    # convert header (4 bytes) to array of 4-byte ints
    a = @data.to_s.unpack('N4')       
    sprintf("(%22s) len=%3d cmd=%8s status=%1d seq=%03d (%s)", self.class.to_s[11..-1], a[0], a[1].to_s(16), a[2], a[3], @msg_body[0..30])
  end
end
