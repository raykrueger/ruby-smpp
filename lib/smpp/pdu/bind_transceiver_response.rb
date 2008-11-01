class Smpp::Pdu::BindTransceiverResponse < Smpp::Pdu::BindRespBase
  @command_id = BIND_TRANSCEIVER_RESP
  handles_cmd BIND_TRANSCEIVER_RESP
end
