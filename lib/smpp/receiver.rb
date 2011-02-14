
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
    when Pdu::DeliverSm
      logger.debug "ESM CLASS #{pdu.esm_class}"
      if pdu.esm_class != 4
        # MO message
        begin
          if @delegate.respond_to?(:mo_received)
            @delegate.mo_received(self, pdu)
          end
          write_pdu(Pdu::DeliverSmResponse.new(pdu.sequence_number))
        rescue => e
          logger.warn "Send Receiver Temporary App Error due to #{e.inspect} raised in delegate"
          write_pdu(Pdu::DeliverSmResponse.new(pdu.sequence_number, Pdu::Base::ESME_RX_T_APPN))
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
