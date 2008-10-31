class Smpp::Pdu::BindTransceiver < Smpp::Pdu::BindBase
  @command_id = BIND_TRANSCEIVER
  handles_cmd BIND_TRANSCEIVER
end
