# -*- encoding : utf-8 -*-
class Smpp::Pdu::BindReceiver < Smpp::Pdu::BindBase
  @command_id = BIND_RECEIVER
  handles_cmd BIND_RECEIVER
end
