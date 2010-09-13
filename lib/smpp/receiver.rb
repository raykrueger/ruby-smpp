
# The SMPP Receiver maintains a unidirectional connection to an SMSC.
# Provide a config hash with connection options to get started. 
# See the sample_gateway.rb for examples of config values.
# The receiver accepts a delegate object that may implement 
# the following (all optional) methods:
#
#   mo_received(receiver, pdu)
#   delivery_report_received(receiver, pdu)
#   bound(receiver)
#   unbound(receiver)

class Smpp::Receiver < Smpp::Base

  def initialize(config, delegate, pdr_storage={})
    super(config)
    @delegate = delegate
    @pdr_storage = pdr_storage
    
    # Array of un-acked MT message IDs indexed by sequence number.
    # As soon as we receive SubmitSmResponse we will use this to find the 
    # associated message ID, and then create a pending delivery report.
    @ack_ids = {}

    ed = @config[:enquire_link_delay_secs] || 5
    comm_inactivity_timeout = 2 * ed
  rescue Exception => ex
    logger.error "Exception setting up receiver: #{ex} at #{ex.backtrace.join("\n")}"
    raise
  end

  # a PDU is received. Parse it and invoke delegate methods.
  def process_pdu(pdu)
    case pdu
    when Pdu::DeliverSm
      write_pdu(Pdu::DeliverSmResponse.new(pdu.sequence_number))
      logger.debug "ESM CLASS #{pdu.esm_class}"
      if pdu.esm_class != 4
        # MO message
        if @delegate.respond_to?(:mo_received)
          @delegate.mo_received(self, pdu)
        end
      else
        # Delivery report
        if @delegate.respond_to?(:delivery_report_received)
          @delegate.delivery_report_received(self, pdu)
        end
      end     
    when Pdu::BindReceiverResponse
      case pdu.command_status
      when Pdu::Base::ESME_ROK
        logger.debug "Bound OK."
        @state = :bound
        if @delegate.respond_to?(:bound)
          @delegate.bound(self)
        end
      when Pdu::Base::ESME_RINVPASWD
        logger.warn "Invalid password."
        # scheduele the connection to close, which eventually will cause the unbound() delegate 
        # method to be invoked.
        close_connection
      when Pdu::Base::ESME_RINVSYSID
        logger.warn "Invalid system id."
        close_connection
      else
        logger.warn "Unexpected BindReceiverResponse. Command status: #{pdu.command_status}"
        close_connection
      end
    when Pdu::SubmitSmResponse
      mt_message_id = @ack_ids.delete(pdu.sequence_number)
      if !mt_message_id
        raise "Got SubmitSmResponse for unknown sequence_number: #{pdu.sequence_number}"
      end
      if pdu.command_status != Pdu::Base::ESME_ROK
        logger.error "Error status in SubmitSmResponse: #{pdu.command_status}"
        if @delegate.respond_to?(:message_rejected)
          @delegate.message_rejected(self, mt_message_id, pdu)
        end
      else
        logger.info "Got OK SubmitSmResponse (#{pdu.message_id} -> #{mt_message_id})"
        if @delegate.respond_to?(:message_accepted)
          @delegate.message_accepted(self, mt_message_id, pdu)
        end        
      end
      # Now we got the SMSC message id; create pending delivery report.
      @pdr_storage[pdu.message_id] = mt_message_id            
    when Pdu::SubmitMultiResponse
      mt_message_id = @ack_ids[pdu.sequence_number]
      if !mt_message_id
        raise "Got SubmitMultiResponse for unknown sequence_number: #{pdu.sequence_number}"
      end
      if pdu.command_status != Pdu::Base::ESME_ROK
        logger.error "Error status in SubmitMultiResponse: #{pdu.command_status}"
        if @delegate.respond_to?(:message_rejected)
          @delegate.message_rejected(self, mt_message_id, pdu)
        end
      else
        logger.info "Got OK SubmitMultiResponse (#{pdu.message_id} -> #{mt_message_id})"
        if @delegate.respond_to?(:message_accepted)
          @delegate.message_accepted(self, mt_message_id, pdu)
        end
      end
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
        @config[:system_type], 
        @config[:source_ton], 
        @config[:source_npi], 
        @config[:source_address_range])
    write_pdu(pdu)
  end
end
