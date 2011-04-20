# Sending an MT message to multiple addresses
# Author: Abhishek Parolkar, (abhishek[at]parolkar.com)
#TODO: Implement from_wire_data for this pdu class.
class Smpp::Pdu::SubmitMulti < Smpp::Pdu::Base
  IS_SMEADDR = 1 # type of dest_flag
  IS_DISTLISTNAME = 2 #type of dest_flag  

  # Note: short_message (the SMS body) must be in iso-8859-1 format
  def initialize(source_addr, destination_addr_array, short_message, options={})
    options.merge!(
      :esm_class => 0,    # default smsc mode
      :dcs => 3           # iso-8859-1
    ) { |key, old_val, new_val| old_val } 
  
    @msg_body = short_message
    
    udh = options[:udh]          
    service_type            = ''
    source_addr_ton         = 0 # network specific
    source_addr_npi         = 1 # unknown
    number_of_dests         = destination_addr_array.length # Max value can be 254
    dest_addr_ton           = 1 # international
    dest_addr_npi           = 1 # unknown
    dest_addresses          = build_destination_addresses(destination_addr_array,dest_addr_ton,dest_addr_npi,IS_SMEADDR) 
    esm_class               = options[:esm_class]
    protocol_id             = 0
    priority_flag           = 0
    schedule_delivery_time  = ''
    validity_period         = ''
    registered_delivery     = 1 # we want delivery notifications
    replace_if_present_flag = 0
    data_coding             = options[:dcs]
    sm_default_msg_id       = 0
    payload                 = udh ? udh + short_message : short_message # this used to be (short_message + "\0")
    sm_length               = payload.length
    
    # craft the string/byte buffer
    pdu_body = sprintf("%s\0%c%c%s\0%c%s\0%c%c%c%s\0%s\0%c%c%c%c%c%s", service_type, source_addr_ton, source_addr_npi, source_addr, number_of_dests,dest_addresses, esm_class, protocol_id, priority_flag, schedule_delivery_time, validity_period,
    registered_delivery, replace_if_present_flag, data_coding, sm_default_msg_id, sm_length, payload)
    super(SUBMIT_MULTI, 0, next_sequence_number, pdu_body)        
  end
  
  # some special formatting is needed for SubmitSm PDUs to show the actual message content
  def to_human
    # convert header (4 bytes) to array of 4-byte ints
    a = @data.to_s.unpack('N4')       
    sprintf("(%22s) len=%3d cmd=%8s status=%1d seq=%03d (%s)", self.class.to_s[11..-1], a[0], a[1].to_s(16), a[2], a[3], @msg_body[0..30])
  end

  def build_destination_addresses(dest_array,dest_addr_ton,dest_addr_npi, dest_flag = IS_SMEADDR)
    formatted_array = Array.new
    dest_array.each { |dest_elem|
      if dest_flag == IS_SMEADDR
        packet_str = sprintf("%c%c%c%s",IS_SMEADDR,dest_addr_ton,dest_addr_npi,dest_elem)
        formatted_array.push(packet_str)

      elsif dest_flag == IS_DISTLISTNAME
        packet_str = sprintf("%c%s",IS_SMEADDR,dest_elem)
                          formatted_array.push(packet_str)

      end

    }

    formatted_array.join("\0");
  end
  
end
