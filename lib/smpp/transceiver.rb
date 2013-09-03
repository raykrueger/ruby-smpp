# encoding: UTF-8

# The SMPP Transceiver maintains a bidirectional connection to an SMSC.
# Provide a config hash with connection options to get started. 
# See the sample_gateway.rb for examples of config values.
# The transceiver accepts a delegate object that may implement 
# the following (all optional) methods:
#
#   mo_received(transceiver, pdu)
#   delivery_report_received(transceiver, pdu)
#   message_accepted(transceiver, mt_message_id, pdu)
#   message_rejected(transceiver, mt_message_id, pdu)
#   bound(transceiver)
#   unbound(transceiver)

class Smpp::Transceiver < Smpp::SenderBase


end
