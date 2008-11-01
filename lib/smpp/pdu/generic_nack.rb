# signals invalid message header
class Smpp::Pdu::GenericNack < Smpp::Pdu::Base
  handles_cmd GENERIC_NACK

  attr_accessor :error_code

  def initialize(seq, error_code, original_sequence_code = nil)
    #TODO: original_sequence_code used to be passed to this function
    #however, a GENERIC_NACK has only one sequence number and no body
    #so this is a useless variable.  I leave it here only to preserve
    #the API, but it has no practical use.
    seq ||= next_sequence_number
    super(GENERIC_NACK, error_code, seq)
    @error_code = error_code
  end

  def self.from_wire_data(seq, status, body)
    new(seq,status,body) 
  end
end        
