class Smpp::Pdu::BindTransmitter < Smpp::Pdu::BindBase
  @command_id = BIND_TRANSMITTER
  handles_cmd BIND_TRANSMITTER
end
