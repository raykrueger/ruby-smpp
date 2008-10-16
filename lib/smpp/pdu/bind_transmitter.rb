class Smpp::Pdu::BindTransmitter < Smpp::Pdu::Base
  attr_accessor :system_id, :password, :addr_ton, :add_npi, :address_range
  def initialize(the_system_id, the_password, the_addr_ton, the_addr_npi, the_address_range, body = nil, seq = nil)
    if body.blank?
      # generate a body given the individual params
      logger.info "setting up a new transmitter from a set of params"
      body = sprintf("%s\0%s\0\0%c%c%c%s\0", the_system_id, the_password, 0x34, the_addr_ton, the_addr_npi, the_address_range)
    else
      # otherwise unpack the given body into the params
      logger.info "setting up a new transmitter from a pdu body"
      system_id, password, addr_ton, add_npi, address_range = body.unpack('Z*Z**CCCZ*')
    end
    seq ||= next_sequence_number
    super(BIND_TRANSMITTER, 0, seq, body)
  end
end
