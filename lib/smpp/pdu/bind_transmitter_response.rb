# -*- encoding : utf-8 -*-
class Smpp::Pdu::BindTransmitterResponse < Smpp::Pdu::BindRespBase
  @command_id = BIND_TRANSMITTER_RESP
  handles_cmd BIND_TRANSMITTER_RESP
end
