# Received for MO message or delivery notification
class Smpp::Pdu::DeliverSm < Smpp::Pdu::Base 
  handles_cmd DELIVER_SM
  attr_reader :service_type, :source_addr_ton, :source_addr_npi, :source_addr, :dest_addr_ton, :dest_addr_npi, 
              :destination_addr, :esm_class, :protocol_id, :priority_flag, :schedule_delivery_time, 
              :validity_period, :registered_delivery, :replace_if_present_flag, :data_coding, 
              :sm_default_msg_id, :sm_length, :stat, :msg_reference, :udh, :short_message,
              :message_state, :receipted_message_id

  def initialize(source_addr, destination_addr, short_message, options={}, seq=nil) 
    
    @udh = options[:udh]      
    @service_type            = options[:service_type]? options[:service_type] :''
    @source_addr_ton         = options[:source_addr_ton]?options[:source_addr_ton]:0 # network specific
    @source_addr_npi         = options[:source_addr_npi]?options[:source_addr_npi]:1 # unknown
    @source_addr             = source_addr
    @dest_addr_ton           = options[:dest_addr_ton]?options[:dest_addr_ton]:1 # international
    @dest_addr_npi           = options[:dest_addr_npi]?options[:dest_addr_npi]:1 # unknown 
    @destination_addr        = destination_addr
    @esm_class               = options[:esm_class]?options[:esm_class]:0 # default smsc mode
    @protocol_id             = options[:protocol_id]?options[:protocol_id]:0
    @priority_flag           = options[:priority_flag]?options[:priority_flag]:1
    @schedule_delivery_time  = options[:schedule_delivery_time]?options[:schedule_delivery_time]:''
    @validity_period         = options[:validity_period]?options[:validity_period]:''
    @registered_delivery     = options[:registered_delivery]?options[:registered_delivery]:1 # we want delivery notifications
    @replace_if_present_flag = options[:replace_if_present_flag]?options[:replace_if_present_flag]:0
    @data_coding             = options[:data_coding]?options[:data_coding]:3 # iso-8859-1
    @sm_default_msg_id       = options[:sm_default_msg_id]?options[:sm_default_msg_id]:0
    @short_message           = short_message
    payload                  = @udh ? @udh + @short_message : @short_message 
    @sm_length               = payload.length

    #fields set for delivery report
    @stat                    = options[:stat]
    @msg_reference           = options[:msg_reference]
    @receipted_message_id    = options[:receipted_message_id]
    @message_state           = options[:message_state]

    pdu_body = sprintf("%s\0%c%c%s\0%c%c%s\0%c%c%c%s\0%s\0%c%c%c%c%c%s", @service_type, @source_addr_ton, @source_addr_npi, @source_addr,
    @dest_addr_ton, @dest_addr_npi, @destination_addr, @esm_class, @protocol_id, @priority_flag, @schedule_delivery_time, @validity_period,
    @registered_delivery, @replace_if_present_flag, @data_coding, @sm_default_msg_id, @sm_length, payload)

    seq ||= next_sequence_number

    super(DELIVER_SM, 0, seq, pdu_body)
  end

  def self.from_wire_data(seq, status, body)
    options = {}
    # brutally unpack it
    options[:service_type], 
    options[:source_addr_ton], 
    options[:source_addr_npi], 
    source_addr, 
    options[:dest_addr_ton], 
    options[:dest_addr_npi], 
    destination_addr, 
    options[:esm_class], 
    options[:protocol_id],
    options[:priority_flag], 
    options[:schedule_delivery_time], 
    options[:validity_period], 
    options[:registered_delivery], 
    options[:replace_if_present_flag], 
    options[:data_coding], 
    options[:sm_default_msg_id],
    options[:sm_length], 
    remaining_bytes = body.unpack('Z*CCZ*CCZ*CCCZ*Z*CCCCCa*')    

    short_message = remaining_bytes.slice!(0...options[:sm_length])

    #everything left in remaining_bytes is 3.4 optional parameters
    optional_parameters(remaining_bytes).each do |tlv|
      if OPTIONAL_MESSAGE_STATE == tlv[:tag]
        options[:message_state] = tlv[:value].unpack('C')

      elsif OPTIONAL_RECEIPTED_MESSAGE_ID == tlv[:tag]
        options[:receipted_message_id] = tlv[:value].unpack('A*')

      end
    end


    #Note: if the SM is a delivery receipt (esm_class=4) then the short_message _may_ be in this format:  
    # "id:Smsc2013 sub:1 dlvrd:1 submit date:0610171515 done date:0610171515 stat:0 err:0 text:blah"
    # or this format:
    # "4790000000SMSAlert^id:1054BC63 sub:0 dlvrd:1 submit date:0610231217 done date:0610231217 stat:DELIVRD err: text:"
    # (according to the SMPP spec, the format is vendor specific)
    # For example, Tele2 (Norway):
    # "<msisdn><shortcode>?id:10ea34755d3d4f7a20900cdb3349e549 sub:001 dlvrd:001 submit date:0611011228 done date:0611011230 stat:DELIVRD err:000 Text:abc'!10ea34755d3d4f7a20900cdb3349e549"
    if options[:esm_class] == 4
      msg_ref_match = short_message.match(/id:([^ ]*)/)
      if msg_ref_match
        options[:msg_reference] = msg_ref_match[1]
      end
      
      stat_match = short_message.match(/stat:([^ ]*)/)
      if stat_match
        options[:stat] = stat_match[1]
      end
      
      Smpp::Base.logger.debug "DeliverSM with source_addr=#{source_addr}, destination_addr=#{destination_addr}, msg_reference=#{options[:msg_reference]}, stat=#{options[:stat]}"
    else
      Smpp::Base.logger.debug "DeliverSM with source_addr=#{source_addr}, destination_addr=#{destination_addr}"
    end    
    
    new(source_addr, destination_addr, short_message, options, seq) 
  end
end
