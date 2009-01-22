require 'timeout'
require 'iconv'
require 'scanf'
require 'monitor'
require 'eventmachine'

module Smpp
  class InvalidStateException < Exception; end
    
  class Base < EventMachine::Connection
    include Smpp
    
    # :bound or :unbound
    attr_accessor :state
    
    # queries the state of the transmitter - is it bound?
    def unbound?
      @state == :unbound
    end
    
    def bound?
      @state == :bound
    end
    
    def Base.logger
      @@logger
    end

    def Base.logger=(logger)
      @@logger = logger
    end

    def logger
      @@logger
    end
    
    def initialize(config)
      @state = :unbound
      @config = config
      @data = ""
    end
    
    # invoked by EventMachine when connected
    def post_init
      # send Bind PDU if we are a binder (eg
      # Receiver/Transmitter/Transceiver
      send_bind unless defined?(am_server?) && am_server?

      # start timer that will periodically send enquire link PDUs
      start_enquire_link_timer(@config[:enquire_link_delay_secs]) if @config[:enquire_link_delay_secs]
    rescue Exception => ex
      logger.error "Error starting RX: #{ex.message} at #{ex.backtrace[0]}"
    end

    # sets up a periodic timer that will periodically enquire as to the
    # state of the connection
    # Note: to add in custom executable code (that only runs on an open
    # connection), derive from the appropriate Smpp class and overload the
    # method named: periodic_call_method
    def start_enquire_link_timer(delay_secs)
      logger.info "Starting enquire link timer (with #{delay_secs}s interval)"
      EventMachine::PeriodicTimer.new(delay_secs) do 
        if error?
          logger.warn "Link timer: Connection is in error state. Disconnecting."
          close_connection
        elsif unbound?
          logger.warn "Link is unbound, waiting until next #{delay_secs} interval before querying again"
        else

          # if the user has defined a method to be called periodically, do
          # it now - and continue if it indicates to do so
          rval = defined?(periodic_call_method) ? periodic_call_method : true

          # only send an OK if this worked
          write_pdu Pdu::EnquireLink.new if rval 
        end
      end
    end

    # EventMachine::Connection#receive_data
    def receive_data(data)
      #append data to buffer
      @data << data

      while (@data.length >=4)
        cmd_length = @data[0..3].unpack('N').first
        if(@data.length < cmd_length)
          #not complete packet ... break
          break
        end
        
        pkt = @data.slice!(0,cmd_length)

        # parse incoming PDU
        pdu = read_pdu(pkt)

        # let subclass process it
        process_pdu(pdu) if pdu

      end
    end
    
    # EventMachine::Connection#unbind
    # Invoked by EM when connection is closed. Delegates should consider
    # breaking the event loop and reconnect when they receive this callback.
    def unbind
      if @delegate.respond_to?(:unbound)
        @delegate.unbound(self)
      end
    end
    
    def send_unbind
      write_pdu Pdu::Unbind.new
      @state = :unbound
    end

    # process common PDUs
    # returns true if no further processing necessary
    def process_pdu(pdu)      
      case pdu
      when Pdu::EnquireLinkResponse
        # nop
      when Pdu::EnquireLink
        write_pdu(Pdu::EnquireLinkResponse.new(pdu.sequence_number))
      when Pdu::Unbind
        @state = :unbound
        write_pdu(Pdu::UnbindResponse.new(pdu.sequence_number, Pdu::Base::ESME_ROK))
        close_connection
      when Pdu::UnbindResponse      
        logger.info "Unbound OK. Closing connection."
        close_connection
      when Pdu::GenericNack
        logger.warn "Received NACK! (error code #{pdu.error_code})."
        # we don't take this lightly: close the connection
        close_connection
      else
        logger.warn "(#{self.class.name}) Received unexpected PDU: #{pdu.to_human}."
        close_connection
      end
    end

    private  
    def write_pdu(pdu)
      logger.debug "<- #{pdu.to_human}"
      send_data pdu.data
    end

    def read_pdu(data)
      pdu = nil
      # we may either receive a new request or a response to a previous response.
      begin        
        pdu = Pdu::Base.create(data)
        if !pdu
          logger.warn "Not able to parse PDU!"
        else
          logger.debug "-> " + pdu.to_human          
        end
      rescue Exception => ex
        logger.error "Exception while reading PDUs: #{ex} in #{ex.backtrace[0]}"
        raise
      end
      pdu
    end    
  end
end
