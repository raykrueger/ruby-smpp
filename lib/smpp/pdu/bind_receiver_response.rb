class Smpp::Pdu::BindReceiverResponse < Smpp::Pdu::BindRespBase
  @command_id = BIND_RECEIVER_RESP
  handles_cmd BIND_RECEIVER_RESP
end
