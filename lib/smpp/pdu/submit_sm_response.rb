class Smpp::Pdu::SubmitSmResponse < Smpp::Pdu::Base
  handles_cmd SUBMIT_SM_RESP

  attr_accessor :message_id
  attr_accessor :optional_parameters

  def initialize(seq, status, message_id, optional_parameters=nil)
    seq ||= next_sequence_number
    body = message_id.to_s + "\000"
    super(SUBMIT_SM_RESP, status, seq, body)
    @message_id = message_id
    @optional_parameters = optional_parameters
  end

  def optional_parameter(tag)
    if optional_parameters 
      if param = optional_parameters[tag]
        param.value
      end
    end
  end

  def self.from_wire_data(seq, status, body)
    message_id, remaining_bytes = body.unpack("Z*a*")
    optionals = nil
    if remaining_bytes && !remaining_bytes.empty?
      optionals = parse_optional_parameters(remaining_bytes)
    end
    new(seq, status, message_id, optionals)
  end
end
