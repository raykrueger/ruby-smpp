# signals invalid message header
class Smpp::Pdu::GenericNack < Smpp::Pdu::Base
  attr_accessor :error_code
  def initialize(seq, error_code, original_sequence_code)
    super(GENERIC_NACK, error_code, seq, "Error: #{error_code} Problem sequence: #{original_sequence_code.blank? ? 'unknown' : original_sequence_code }")
    @error_code = error_code
  end
end        
