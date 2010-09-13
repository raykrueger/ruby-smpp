#TODO This should be made prettier with mocha
class ResponsiveDelegate
  attr_reader :seq, :event_counter

  def initialize
    @seq = 0
    @event_counter = nil
  end
  def seq
    @seq += 1
  end
  def count_function
    func = caller(1)[0].split("`")[1].split("'")[0].to_sym
    @event_counter = {} unless @event_counter.is_a?(Hash)
    @event_counter[func] = 0 if @event_counter[func].nil?
    @event_counter[func]+=1
  end

  def mo_received(transceiver, pdu)
    count_function
    puts "** mo_received"
  end

  def delivery_report_received(transceiver, pdu)
    count_function
    puts "** delivery_report_received"
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    count_function
    puts "** message_sent"
    #sending messages from delegate to escape making a fake message sender - not nice :(
    $tx.send_mt(self.seq, 1, 2, "short_message @ message_accepted")
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    count_function
    puts "** message_rejected"
    $tx.send_mt(self.seq, 1, 2, "short_message @ message_rejected")
  end

  def bound(transceiver)
    count_function
    puts "** bound"
    $tx.send_mt(self.seq, 1, 2, "short_message @ bound")
  end

  def unbound(transceiver)
    count_function
    puts "** unbound"
    EventMachine::stop_event_loop
  end
end
