require 'timeout'
require 'scanf'
require 'monitor'
require 'eventmachine'

module Smpp
  class InvalidStateException < Exception; end
    
  class Base < EventMachine::Connection
    include Smpp
    
    # :bound or :unbound
    attr_accessor :state
    
    def initialize(config, delegate)
      @state = :unbound
      @config = config
      @data = ""
      @delegate = delegate

      # Array of un-acked MT message IDs indexed by sequence number.
      # As soon as we receive SubmitSmResponse we will use this to find the 
      # associated message ID, and then create a pending delivery report.
      @ack_ids = {}

      ed = @config[:enquire_link_delay_secs] || 5
      comm_inactivity_timeout = 2 * ed
    end

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

        begin
          # parse incoming PDU
          pdu = read_pdu(pkt)

          # let subclass process it
          process_pdu(pdu) if pdu
        rescue Exception => e
          logger.error "Error receiving data: #{e}\n#{e.backtrace.join("\n")}"
          if @delegate.respond_to?(:data_error)
            @delegate.data_error(e)
          end
        end

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
      when Pdu::DeliverSm
        begin
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
          write_pdu(Pdu::DeliverSmResponse.new(pdu.sequence_number))
        rescue => e
          logger.warn "Send Receiver Temporary App Error due to #{e.inspect} raised in delegate"
          write_pdu(Pdu::DeliverSmResponse.new(pdu.sequence_number, Pdu::Base::ESME_RX_T_APPN))
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
        logger.warn "(#{self.class.name}) Received unexpected PDU: #{pdu.to_human}."
        close_connection
      end
    end

    private  
    def write_pdu(pdu)
      logger.debug "<- #{pdu.to_human}"
      hex_debug pdu.data, "<- "
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
        hex_debug data, "-> "
      rescue Exception => ex
        logger.error "Exception while reading PDUs: #{ex} in #{ex.backtrace[0]}"
        raise
      end
      pdu
    end

    def hex_debug(data, prefix = "")
      Base.hex_debug(data, prefix)
    end

    def Base.hex_debug(data, prefix = "")
      logger.debug do
        message = "Hex dump follows:\n"
        hexdump(data).each_line do |line| 
          message << (prefix + line.chomp + "\n")
        end
        message
      end
    end

    def Base.hexdump(target)
      width=16
      group=2

      output = ""
      n=0
      ascii=''
      target.each_byte { |b|
        if n%width == 0
          output << "%s\n%08x: "%[ascii,n]
          ascii='| '
        end
        output << "%02x"%b
        output << ' ' if (n+=1)%group==0
        ascii << "%s"%b.chr.tr('^ -~','.')
      }
      output << ' '*(((2+width-ascii.size)*(2*group+1))/group.to_f).ceil+ascii
      output[1..-1]
    end    
  end
end
