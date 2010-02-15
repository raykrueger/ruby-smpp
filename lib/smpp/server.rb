# --------
# This is experimental stuff submitted by taryn@taryneast.org
# --------

# the opposite of a client-based receiver, the server transmitter will send
# out MOs to the client when set up
class Smpp::Server < Smpp::Base

  attr_accessor :bind_status

  # Expects a config hash, 
  # a proc to invoke for incoming (MO) messages,
  # a proc to invoke for delivery reports,
  # and optionally a hash-like storage for pending delivery reports.
  def initialize(config, received_messages = [], sent_messages = [])
    super(config)
    @state = :unbound
    @received_messages = received_messages
    @sent_messages = sent_messages
    
    ed = @config[:enquire_link_delay_secs] || 5
    comm_inactivity_timeout = [ed - 5, 3].max
  rescue Exception => ex
    logger.error "Exception setting up server: #{ex}"
    raise
  end

  
  #######################################################################
  # Session management functions
  #######################################################################
  # Session helpers

  # convenience methods
  # is this session currently bound?
  def bound?
    @state == :bound
  end
  # is this session currently unbound?
  def unbound?
    @state == :unbound
  end
  # set of valid bind statuses
  BIND_STATUSES = {:transmitter => :bound_tx, 
           :receiver => :bound_rx, :transceiver => :bound_trx}
  # set the bind status based on the common-name for the bind class
  def set_bind_status(bind_classname)
    @bind_status = BIND_STATUSES[bind_classname]
  end
  # and kill the bind status when done
  def unset_bind_status
    @bind_status = nil
  end
  # what is the bind_status?
  def bind_status
    @bind_status
  end
  # convenience function - are we able to transmit in this bind-Status?
  def transmitting?
    # not transmitting if not bound
    return false if unbound? || bind_status.nil?
    # receivers can't transmit
    bind_status != :bound_rx
  end
  # convenience function - are we able to receive in this bind-Status?
  def receiving?
    # not receiving if not bound
    return false if unbound? || bind_status.nil?
    # transmitters can't receive
    bind_status != :bound_tx
  end

  def am_server?
    true
  end

  # REVISIT - not sure if these are using the correct data.  Currently just
  # pulls the data straight out of the given pdu and sends it right back.
  #
  def fetch_bind_response_class(bind_classname)
    # check we have a valid classname - probably overkill as only our code
    # will send the classnames through
    raise IOError, "bind class name missing" if bind_classname.nil?
    raise IOError, "bind class name: #{bind_classname} unknown" unless BIND_STATUSES.has_key?(bind_classname)

    case bind_classname
    when :transceiver
      return Smpp::Pdu::BindTransceiverResponse
    when :transmitter
      return Smpp::Pdu::BindTransmitterResponse
    when :receiver
      return Smpp::Pdu::BindReceiverResponse
    end
  end

  # actually perform the action of binding the session to the given session
  # type
  def bind_session(bind_pdu, bind_classname)
    # TODO: probably should not "raise" here - what's better?
    raise IOError, "Session already bound." if bound?
    response_class = fetch_bind_response_class(bind_classname)

    # TODO: look inside the pdu for the password and check it

    send_bind_response(bind_pdu, response_class)

    @state = :bound
    set_bind_status(bind_classname)
  end

  # Send BindReceiverResponse PDU - used in response to a "bind_receiver"
  # pdu.
  def send_bind_response(bind_pdu, bind_class)
    resp_pdu = bind_class.new(
                  bind_pdu.sequence_number, 
                  # currently assume that it binds ok
                  Pdu::Base::ESME_ROK, 
                  # TODO: not sure where we get the system ID
                  # is this the session id?
                  bind_pdu.system_id)
    write_pdu(resp_pdu)
  end
 
  #######################################################################
  # Message submission (transmitter) functions (used by transmitter and
  # transceiver-bound system) 
  # Note - we only support submit_sm message type, not submit_multi or
  # data_sm message types
  #######################################################################
  # Receive an incoming message to send to the network and respond
  # REVISIT = just a stub
  def receive_sm(pdu)
    # TODO: probably should not "raise" here - what's better?
    raise IOError, "Connection not bound." if unbound?
    # Doesn't matter if it's a TX/RX/TRX, have to send a SubmitSmResponse:
    # raise IOError, "Connection not set to receive" unless receiving?

    # Must respond to SubmitSm requests with the same sequence number
    m_seq = pdu.sequence_number
    # add the id to the list of ids of which we're awaiting acknowledgement
    @received_messages << m_seq

    # In theory this is where the MC would actually do something useful with
    # the PDU - eg send it on to the network. We'd check if it worked and
    # send a failure PDU if it failed.
    #
    # Given this is a dummy MC, that's not necessary, so all our responses
    # will be OK.

    # so respond with a successful response
    pdu = Pdu::SubmitSmResponse.new(m_seq, Pdu::Base::ESME_ROK, message_id = '' )
    write_pdu pdu
    @received_messages.delete m_seq
    
    logger.info "Received submit sm message: #{m_seq}"
  end

  #######################################################################
  # Message delivery (receiver) functions (used by receiver and
  # transceiver-bound system)
  #######################################################################
  # When we get an incoming SMS to send on to the client, we need to
  # initiate one of these PDUs.
  # Note - data doesn't have to be valid, as we're not really doing much
  # useful with it. Only the params that will be pulled out by the test
  # system need to be valid.
  def deliver_sm(from, to, message, config = {})
    # TODO: probably should not "raise" here - what's better?
    raise IOError, "Connection not bound." if unbound?
    raise IOError, "Connection not set to receive" unless receiving?
    
    # submit the given message
    new_pdu = Pdu::DeliverSm.new(from, to, message, config)
    write_pdu(new_pdu)
    # add the id to the list of ids of which we're awaiting acknowledgement
    @sent_messages << m_seq

    logger.info "Delivered SM message id: #{m_seq}"

    new_pdu
  end

  # Acknowledge delivery of an outgoing MO message
  # REVISIT = just a stub
  def accept_deliver_sm_response(pdu)
    m_seq = pdu.sequence_number
    # add the id to the list of ids we're awaiting acknowledgement of
    # REVISIT - what id do we need to store?
    unless @sent_messages && @sent_messages.include?(m_seq)
      logger.error("Received deliver response for message for which we have no saved id: #{m_seq}")
    else
      @sent_messages.delete(m_seq)
      logger.info "Acknowledged receipt of SM delivery message id: #{m_seq}"
    end
  end


  # a PDU is received
  # these pdus are all responses to a message sent by the client and require
  # their own special response
  def process_pdu(pdu)
    case pdu
    # client has asked to set up a connection
    when Pdu::BindTransmitter
      bind_session(pdu, :transmitter)
    when Pdu::BindReceiver
      bind_session(pdu, :receiver)
    when Pdu::BindTransceiver
      bind_session(pdu, :transceiver)
    # client has acknowledged receipt of a message we sent to them
    when Pdu::DeliverSmResponse
      accept_deliver_sm_response(pdu) # acknowledge its sending

    # client has asked for a message to be sent
    when Pdu::SubmitSm
      receive_sm(pdu)
    else
      # for generic functions or default fallback
      super(pdu)
    end 
  end
 
end
