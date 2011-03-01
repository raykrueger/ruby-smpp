
# The SMPP Transmitter is the shizzle

class Smpp::Transmitter < Smpp::Base

  def initialize(config, delegate)
    super(config)
    @delegate = delegate

    ed = @config[:enquire_link_delay_secs] || 5
    comm_inactivity_timeout = 2 * ed
  rescue Exception => ex
    logger.error "Exception setting up receiver: #{ex} at #{ex.backtrace.join("\n")}"
    raise
  end

  # a PDU is received. Parse it and invoke delegate methods.
  def process_pdu(pdu)
    case pdu
    when Pdu::SubmitSmResponse
      logger.debug "Recieved SubmitSmResponse success?=#{pdu.command_status == Pdu::Base::ESME_ROK}"
      #mt_message_id = @ack_ids.delete(pdu.sequence_number)
      # if !mt_message_id
      #   raise "Got SubmitSmResponse for unknown sequence_number: #{pdu.sequence_number}"
      # end
      # if pdu.command_status != Pdu::Base::ESME_ROK
      #   logger.error "Error status in SubmitSmResponse: #{pdu.command_status}"
      #   if @delegate.respond_to?(:message_rejected)
      #     @delegate.message_rejected(self, mt_message_id, pdu)
      #   end
      # else
      #   logger.info "Got OK SubmitSmResponse (#{pdu.message_id} -> #{mt_message_id})"
      #   if @delegate.respond_to?(:message_accepted)
      #     @delegate.message_accepted(self, mt_message_id, pdu)
      #   end        
      # end
      # # Now we got the SMSC message id; create pending delivery report.
      # @pdr_storage[pdu.message_id] = mt_message_id
    when Pdu::BindTransmitterResponse
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
    else
      super
    end
  end

  # Send an MT SMS message. Delegate will receive message_accepted callback when SMSC
  # acknowledges, or the message_rejected callback upon error
  def send_mt(message_id, source_addr, destination_addr, short_message, options={})
    logger.debug "Sending MT: #{short_message}"
    if @state == :bound
      pdu = Pdu::SubmitSm.new(source_addr, destination_addr, short_message, options)
      write_pdu pdu

      # keep the message ID so we can associate the SMSC message ID with our message
      # when the response arrives.
      # @ack_ids[pdu.sequence_number] = message_id
    else
      raise InvalidStateException, "Transmitter is unbound. Cannot send MT messages."
    end
  end

  def send_bind
    raise IOError, 'Transmitter already bound.' unless unbound?
    pdu = Pdu::BindTransmitter.new(
        @config[:system_id],
        @config[:password],
        @config[:system_type],
        @config[:source_ton],
        @config[:source_npi],
        @config[:source_address_range])
    write_pdu(pdu)
  end
end
