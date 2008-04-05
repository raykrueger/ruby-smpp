class Smpp::Pdu::BindTransceiver < Smpp::Pdu::Base
  def initialize(system_id, password, addr_ton, addr_npi, address_range)
    body = sprintf("%s\0%s\0\0%c%c%c%s\0", system_id, password, 0x34, addr_ton, addr_npi, address_range)
    super(BIND_TRANSCEIVER, 0, next_sequence_number, body)
  end
end
