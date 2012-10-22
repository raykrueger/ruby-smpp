
# The SMPP Transmitter is the shizzle

class Smpp::Transmitter < Smpp::Base

  def initialize(config, delegate)
    super

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
      if pdu.command_status == Pdu::Base::ESME_ROK
        logger.debug "Received SubmitSmResponse successfully"
      else
        logger.debug "Received SubmitSmResponse failed: #{pdu.command_status}"
      end
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
        # schedule the connection to close, which eventually will cause the unbound() delegate
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
    else
      raise InvalidStateException, "Transmitter is unbound. Cannot send MT messages."
    end
  end

  def send_concat_mt(message_id, source_addr, destination_addr, message, options = {})
      if @state == :bound
        # Split the message into parts of 134 characters.
        parts = []
        while message.size > 0 do
          parts << message.slice!(0..133)
        end
        0.upto(parts.size-1) do |i|
          udh = sprintf("%c", 5)            # UDH is 5 bytes.
          udh << sprintf("%c%c", 0, 3)      # This is a concatenated message
          udh << sprintf("%c", message_id)  # The ID for the entire concatenated message
          udh << sprintf("%c", parts.size)  # How many parts this message consists of

          udh << sprintf("%c", i+1)         # This is part i+1

          combined_options = {
            :esm_class => 64,               # This message contains a UDH header.
            :udh => udh
          }.merge(options)

          pdu = Smpp::Pdu::SubmitSm.new(source_addr, destination_addr, parts[i], combined_options)
          write_pdu pdu
        end
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
