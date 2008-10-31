class Smpp::Pdu::BindRespBase < Smpp::Pdu::Base
  class << self; attr_accessor :command_id ; end
  attr_accessor :system_id

  def initialize(seq, status, system_id)
    seq ||= next_sequence_number
    system_id = system_id.to_s + "\000"
    super(self.class.command_id, status, seq, system_id) # pass in system_id as body for simple debugging
    @system_id = system_id
  end

  def self.from_wire_data(seq, status, body)
    system_id = body.chomp("\000")
    new(seq, status, system_id)
  end

end
