
# The SMPP Transceiver maintains a bidirectional connection to an SMSC.
# Provide a config hash with connection options to get started. 
# See the sample_gateway.rb for examples of config values.
# The transceiver accepts a delegate object that may implement 
# the following (all optional) methods:
#
#   mo_received(transceiver, source_addr, destination_addr, short_message)
#   delivery_report_received(transceiver, msg_reference, stat, pdu)
#   message_accepted(transceiver, mt_message_id, smsc_message_id)
#   bound(transceiver)
#   unbound(transceiver)

class Smpp::Transceiver < Smpp::Base

  def initialize(config, delegate, pdr_storage={})
    super(config)
    @delegate = delegate
    @pdr_storage = pdr_storage
    
    # Array of un-acked MT message IDs indexed by sequence number.
    # As soon as we receive SubmitSmResponse we will use this to find the 
    # associated message ID, and then create a pending delivery report.
    @ack_ids = Array.new(512)         
    
    ed = @config[:enquire_link_delay_secs] || 5
    comm_inactivity_timeout = 2 * ed
  rescue Exception => ex
    logger.error "Exception setting up transceiver: #{ex} at #{ex.backtrace.join("\n")}"
    raise
  end

  # Send an MT SMS message. Delegate will receive message_accepted callback when SMSC 
  # acknowledges. 
  def send_mt(message_id, source_addr, destination_addr, short_message, options={})
    logger.debug "Sending MT: #{short_message}"
    if @state == :bound
      pdu = Pdu::SubmitSm.new(source_addr, destination_addr, short_message, options)
      write_pdu pdu

      # keep the message ID so we can associate the SMSC message ID with our message
      # when the response arrives.      
      @ack_ids[pdu.sequence_number] = message_id
    else
      raise InvalidStateException, "Transceiver is unbound. Cannot send MT messages."
    end
  end

  # Send a concatenated message with a body of > 160 characters as multiple messages.
  def send_concat_mt(message_id, source_addr, destination_addr, message, options = {})
    logger.debug "Sending concatenated MT: #{message}"
    if @state == :bound
      # Split the message into parts of 153 characters. (160 - 7 characters for UDH)
      parts = []
      while message.size > 0 do
        parts << message.slice!(0..152)
      end
      
      0.upto(parts.size-1) do |i|
        udh = sprintf("%c", 5)            # UDH is 5 bytes.
        udh << sprintf("%c%c", 0, 3)      # This is a concatenated message 
        udh << sprintf("%c", message_id)  # The ID for the entire concatenated message
        udh << sprintf("%c", parts.size)  # How many parts this message consists of
        udh << sprintf("%c", i+1)         # This is part i+1
        
        options = {
          :esm_class => 64,               # This message contains a UDH header.
          :udh => udh 
        }
        
        pdu = Pdu::SubmitSm.new(source_addr, destination_addr, parts[i], options)
        write_pdu pdu
        
        # This is definately a bit hacky - multiple PDUs are being associated with a single
        # message_id.
        @ack_ids[pdu.sequence_number] = message_id
      end
    else
      raise InvalidStateException, "Transceiver is unbound. Connot send MT messages."
    end
  end

  # Send  MT SMS message for multiple dest_address
  # Author: Abhishek Parolkar (abhishek[at]parolkar.com)
  # USAGE: $tx.send_multi_mt(123, "9100000000", ["9199000000000","91990000000001","9199000000002"], "Message here")
  def send_multi_mt(message_id, source_addr, destination_addr_arr, short_message, options={})
    logger.debug "Sending Multiple MT: #{short_message}"
    if @state == :bound
      pdu = Pdu::SubmitMulti.new(source_addr, destination_addr_arr, short_message, options)
      write_pdu pdu

      # keep the message ID so we can associate the SMSC message ID with our message
      # when the response arrives.      
      @ack_ids[pdu.sequence_number] = message_id
    else
      raise InvalidStateException, "Transceiver is unbound. Cannot send MT messages."
    end
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
          @delegate.mo_received(self, pdu.source_addr, pdu.destination_addr, pdu.short_message)
        end
      else
        # Delivery report
        if @delegate.respond_to?(:delivery_report_received)
          @delegate.delivery_report_received(self, pdu.msg_reference.to_s, pdu.stat, pdu)
        end
      end     
    when Pdu::BindTransceiverResponse
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
        logger.warn "Unexpected BindTransceiverResponse. Command status: #{pdu.command_status}"
        close_connection
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
        if @delegate.respond_to?(:message_accepted)
          @delegate.message_accepted(self, mt_message_id, pdu.message_id)
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
      else
        logger.info "Got OK SubmitMultiResponse (#{pdu.message_id} -> #{mt_message_id})"
        if @delegate.respond_to?(:message_accepted)
          @delegate.message_accepted(self, mt_message_id, pdu.message_id)
        end
      end
    else
      super
    end 
  end

  # Send BindTransceiverResponse PDU.
  def send_bind
    raise IOError, 'Receiver already bound.' unless unbound?
    pdu = Pdu::BindTransceiver.new(
        @config[:system_id], 
        @config[:password],
        @config[:system_type], 
        @config[:source_ton], 
        @config[:source_npi], 
        @config[:source_address_range])
    write_pdu(pdu)
  end
end
