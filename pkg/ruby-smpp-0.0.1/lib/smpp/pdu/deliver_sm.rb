# Received for MO message or delivery notification
class Smpp::Pdu::DeliverSm < Smpp::Pdu::Base
  attr_reader :source_addr, :destination_addr, :short_message, :source_addr, :esm_class, :msg_reference, :stat
  def initialize(seq, status, body)
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
    @short_message = body.unpack('Z*CCZ*CCZ*CCCZ*Z*CCCCCa*')
    logger.debug "DeliverSM with source_addr=#{@source_addr}, destination_addr=#{@destination_addr}"
    
    # Note: if the SM is a delivery receipt (esm_class=4) then the short_message _may_ be in this format:  
    # "id:Smsc2013 sub:1 dlvrd:1 submit date:0610171515 done date:0610171515 stat:0 err:0 text:blah"
    # or this format:
    # "4790000000SMSAlert^id:1054BC63 sub:0 dlvrd:1 submit date:0610231217 done date:0610231217 stat:DELIVRD err: text:"
    # (according to the SMPP spec, the format is vendor specific)
    # For example, Tele2 (Norway):
    # "<msisdn><shortcode>?id:10ea34755d3d4f7a20900cdb3349e549 sub:001 dlvrd:001 submit date:0611011228 done date:0611011230 stat:DELIVRD err:000 Text:abc'!10ea34755d3d4f7a20900cdb3349e549"
    if @esm_class == 4
      @msg_reference = @short_message.scanf('id:%s').to_s
      # @stat must be parsed according to the SMSC vendor's specifications (see comment above)
      @stat = 0
    end
    super(DELIVER_SM, status, seq, body)
  end
end