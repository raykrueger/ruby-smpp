class Smpp::Receiver < Smpp::Base

  # Expects a config hash, 
  # a proc to invoke for incoming (MO) messages,
  # a proc to invoke for delivery reports,
  # and optionally a hash-like storage for pending delivery reports.
  def initialize(config, mo_proc, dr_proc, pdr_storage={})
    super(config)
    @state = :unbound
    @mo_proc = mo_proc
    @dr_proc = dr_proc      
    @pdr_storage = pdr_storage   
    
    # Array of un-acked MT message IDs indexed by sequence number.
    # As soon as we receive SubmitSmResponse we will use this to find the 
    # associated message ID, and then create a pending delivery report.
    @ack_ids = Array.new(512)         
    
    ed = @config[:enquire_link_delay_secs] || 5
    comm_inactivity_timeout = [ed - 5, 3].max
  rescue Exception => ex
    logger.error "Exception setting up transceiver: #{ex}"
    raise
  end

  # a PDU is received
  def process_pdu(pdu)
    case pdu
    when Pdu::DeliverSm
      write_pdu(Pdu::DeliverSmResponse.new(pdu.sequence_number))
      logger.debug "ESM CLASS #{pdu.esm_class}"
      if pdu.esm_class != 4
        # MO message; invoke MO proc
        @mo_proc.call(pdu.source_addr, pdu.destination_addr, pdu.short_message)
      else
        # Invoke DR proc (let the owner of the block do the mapping from msg_reference to mt_id)
        @dr_proc.call(pdu.msg_reference.to_s, pdu)
      end     
    when Pdu::BindReceiverResponse
      case pdu.command_status
      when Pdu::Base::ESME_ROK
        logger.debug "Bound OK."
        @state = :bound
      when Pdu::Base::ESME_RINVPASWD
        logger.warn "Invalid password."
        EventMachine::stop_event_loop
      when Pdu::Base::ESME_RINVSYSID
        logger.warn "Invalid system id."
        EventMachine::stop_event_loop
      else
        logger.warn "Unexpected BindReceiverResponse. Command status: #{pdu.command_status}"
        EventMachine::stop_event_loop
      end
    when Pdu::SubmitSmResponse
      mt_message_id = @ack_ids[pdu.sequence_number]
      if !mt_message_id
        raise "Got SubmitSmResponse for unknown sequence_number: #{pdu.sequence_number}"
      end
      if pdu.command_status != Pdu::Base::ESME_ROK
        logger.error "Error status in SubmitSmResponse: #{pdu.command_status}"
      else
        logger.info "Got OK SubmitSmResponse (#{pdu.message_id} -> #{mt_message_id})"
      end
      # Now we got the SMSC message id; create pending delivery report
      @pdr_storage[pdu.message_id] = mt_message_id
    else
      super
    end 
  end

  # Send BindReceiverResponse PDU.
  def send_bind
    raise IOError, 'Receiver already bound.' unless unbound?
    pdu = Pdu::BindReceiver.new(
    @config[:system_id], 
    @config[:password], 
    @config[:source_ton], 
    @config[:source_npi], 
    @config[:source_address_range])
    write_pdu(pdu)
  end
end
