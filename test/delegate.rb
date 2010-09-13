# the delagate receives callbacks when interesting things happen on the connection
class Delegate

  def mo_received(transceiver, pdu)
    puts "** mo_received"
  end

  def delivery_report_received(transceiver, pdu)
    puts "** delivery_report_received"
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    puts "** message_sent"
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    puts "** message_rejected"
  end

  def bound(transceiver)
    puts "** bound"
  end

  def unbound(transceiver)
    puts "** unbound"
    EventMachine::stop_event_loop
  end
end
