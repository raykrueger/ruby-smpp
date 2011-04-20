# The SMPP Receiver maintains a unidirectional connection to an SMSC.
# Provide a config hash with connection options to get started. 
# See the sample_gateway.rb for examples of config values.
# The receiver accepts a delegate object that may implement 
# the following (all optional) methods:
#
#   mo_received(receiver, pdu)
#   delivery_report_received(receiver, pdu)
#   bound(receiver)
#   unbound(receiver)

class Smpp::Receiver < Smpp::Base

  # Send BindReceiverResponse PDU.
  def send_bind
    raise IOError, 'Receiver already bound.' unless unbound?
    pdu = Pdu::BindReceiver.new(
        @config[:system_id], 
        @config[:password],
        @config[:system_type], 
        @config[:source_ton], 
        @config[:source_npi], 
        @config[:source_address_range])
    write_pdu(pdu)
  end

end
