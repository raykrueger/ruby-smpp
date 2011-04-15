require "stringio"

# the delagate receives callbacks when interesting things happen on the connection
class Delegate

  def initialize(output = StringIO.new)
    @output = output
  end

  def mo_received(transceiver, pdu)
    @output.puts "** mo_received"
  end

  def delivery_report_received(transceiver, pdu)
    @output.puts "** delivery_report_received"
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    @output.puts "** message_sent"
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    @output.puts "** message_rejected"
  end

  def bound(transceiver)
    @output.puts "** bound"
  end

  def unbound(transceiver)
    @output.puts "** unbound"
    EventMachine::stop_event_loop
  end
end
