# PDUs are the protcol base units in SMPP
module Smpp::Pdu
  class Base
    # Error constants
    ESME_ROK              = 0x00000000 # OK!
    ESME_RINVMSGLEN       = 0x00000001 # Message Length is invalid 
    ESME_RINVCMDLEN       = 0x00000002 # Command Length is invalid 
    ESME_RINVCMDID        = 0x00000003 # Invalid Command ID 
    ESME_RINVBNDSTS       = 0x00000004 # Incorrect BIND Status for given com- 
    ESME_RALYBND          = 0x00000005 # ESME Already in Bound State 
    ESME_RINVPRTFLG       = 0x00000006 # Invalid Priority Flag 
    ESME_RINVREGDLVFLG    = 0x00000007 # Invalid Registered Delivery Flag 
    ESME_RSYSERR          = 0x00000008 # System Error 
    ESME_RINVSRCADR       = 0x0000000A # Invalid Source Address 
    ESME_RINVDSTADR       = 0x0000000B # Invalid Dest Addr 
    ESME_RINVMSGID        = 0x0000000C # Message ID is invalid 
    ESME_RBINDFAIL        = 0x0000000D # Bind Failed 
    ESME_RINVPASWD        = 0x0000000E # Invalid Password 
    ESME_RINVSYSID        = 0x0000000F # Invalid System ID 
    ESME_RCANCELFAIL      = 0x00000011 # Cancel SM Failed 
    ESME_RREPLACEFAIL     = 0x00000013 # Replace SM Failed 
    ESME_RMSGQFUL         = 0x00000014 # Message Queue Full 
    ESME_RINVSERTYP       = 0x00000015 # Invalid Service Type 
    ESME_RINVNUMDESTS     = 0x00000033 # Invalid number of destinations 
    ESME_RINVDLNAME       = 0x00000034 # Invalid Distribution List name 
    ESME_RINVDESTFLAG     = 0x00000040 # Destination flag is invalid 
    ESME_RINVSUBREP       = 0x00000042 # Invalid ‘submit with replace’ request 
    ESME_RINVESMCLASS     = 0x00000043 # Invalid esm_class field data 
    ESME_RCNTSUBDL        = 0x00000044 # Cannot Submit to Distribution List 
    ESME_RSUBMITFAIL      = 0x00000045 # submit_sm or submit_multi failed 
    ESME_RINVSRCTON       = 0x00000048 # Invalid Source address TON 
    ESME_RINVSRCNPI       = 0x00000049 # Invalid Source address NPI       
    ESME_RINVDSTTON       = 0x00000050 # Invalid Destination address TON 
    ESME_RINVDSTNPI       = 0x00000051 # Invalid Destination address NPI 
    ESME_RINVSYSTYP       = 0x00000053 # Invalid system_type field 
    ESME_RINVREPFLAG      = 0x00000054 # Invalid replace_if_present flag 
    ESME_RINVNUMMSGS      = 0x00000055 # Invalid number of messages 
    ESME_RTHROTTLED       = 0x00000058 # Throttling error (ESME has exceeded allowed message limits)     

    # PDU types
    GENERIC_NACK          = 0X80000000 
    BIND_RECEIVER         = 0X00000001 
    BIND_RECEIVER_RESP    = 0X80000001 
    BIND_TRANSMITTER      = 0X00000002 
    BIND_TRANSMITTER_RESP = 0X80000002 
    BIND_TRANSCEIVER      = 0X00000009
    BIND_TRANSCEIVER_RESP = 0X80000009
    QUERY_SM              = 0X00000003 
    QUERY_SM_RESP         = 0X80000003 
    SUBMIT_SM             = 0X00000004 
    SUBMIT_SM_RESP        = 0X80000004 
    DELIVER_SM            = 0X00000005 
    DELIVER_SM_RESP       = 0X80000005 
    UNBIND                = 0X00000006 
    UNBIND_RESP           = 0X80000006 
    REPLACE_SM            = 0X00000007 
    REPLACE_SM_RESP       = 0X80000007 
    CANCEL_SM             = 0X00000008 
    CANCEL_SM_RESP        = 0X80000008 
    ENQUIRE_LINK          = 0X00000015 
    ENQUIRE_LINK_RESP     = 0X80000015
    SUBMIT_MULTI	  = 0X00000021
    SUBMIT_MULTI_RESP     = 0X80000021
    # PDU sequence number. 
    @@seq = [Time.now.to_i]

    # Add monitor to sequence counter for thread safety
    @@seq.extend(MonitorMixin)

    attr_reader :command_id, :command_status, :sequence_number, :body, :data

    def initialize(command_id, command_status, seq, body='')    
      length = 16 + body.length
      @command_id = command_id
      @command_status = command_status
      @body = body
      @sequence_number = seq
      @data = fixed_int(length) + fixed_int(command_id) + fixed_int(command_status) + fixed_int(seq) + body   
    end      

    def logger
      Smpp::Base.logger
    end

    def to_human
      # convert header (4 bytes) to array of 4-byte ints
      a = @data.to_s.unpack('N4')
      sprintf("(%22s) len=%3d cmd=%8s status=%1d seq=%03d (%s)", self.class.to_s[11..-1], a[0], a[1].to_s(16), a[2], a[3], @body)
    end

    # return int as binary string of 4 octets
    def fixed_int(value)
      sprintf("%c%c%c%c", value >> 24, value >> 16, value >> 8, value & 0xff)
    end

    def next_sequence_number
      Base.next_sequence_number
    end

    def Base.next_sequence_number
      @@seq.synchronize do 
        (@@seq[0] += 1) % 512
      end
    end

    # PDU factory method for common client PDUs (used to create PDUs from wire data)
    def Base.create(data)
      header = data[0..15]
      if !header
        return nil
      end
      len, cmd, status, seq = header.unpack('N4')
      body = data[16..-1]
      case cmd
      when ENQUIRE_LINK:
        EnquireLink.new(seq)
      when ENQUIRE_LINK_RESP:
        EnquireLinkResponse.new(seq)
      when GENERIC_NACK:
        GenericNack.new(seq, status, body)        
      when UNBIND:
        Unbind.new(seq)        
      when UNBIND_RESP:
        UnbindResponse.new(seq, status)        
      when BIND_TRANSMITTER_RESP:
        BindTransmitterResponse.new(seq, status, body) # could be opt'l params too
      when BIND_RECEIVER_RESP:
        BindReceiverResponse.new(seq, status, body) 
      when BIND_TRANSCEIVER_RESP:
        BindTransceiverResponse.new(seq, status, body)
      when SUBMIT_SM_RESP:
        SubmitSmResponse.new(seq, status, body)
      when SUBMIT_MULTI_RESP:
        SubmitMultiResponse.new(seq, status, body)
      when DELIVER_SM:
        DeliverSm.new(seq, status, body)
      else
        Smpp::Base.logger.error "Unknown PDU: 0x#{cmd.to_s(16)}"
        return nil
      end
    end
  end
end
