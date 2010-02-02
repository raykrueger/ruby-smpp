#!/usr/bin/env ruby

# Sample SMS gateway that can receive MOs (mobile originated messages) and
# DRs (delivery reports), and send MTs (mobile terminated messages).
# MTs are, in the name of simplicity, entered on the command line in the format
# <sender> <receiver> <message body>
# MOs and DRs will be dumped to standard out.

require 'rubygems'
require File.dirname(__FILE__) + '/../lib/smpp'

LOGFILE = File.dirname(__FILE__) + "/sms_gateway.log"
Smpp::Base.logger = Logger.new(LOGFILE)

# We use EventMachine to receive keyboard input (which we send as MT messages).
# A "real" gateway would probably get its MTs from a message queue instead.
module KeyboardHandler
  include EventMachine::Protocols::LineText2

  def receive_line(data)
    sender, receiver, *body_parts = data.split
    unless sender && receiver && body_parts.size > 0
      puts "Syntax: <sender> <receiver> <message body>"      
    else
      body = body_parts.join(' ')
      puts "Sending MT from #{sender} to #{receiver}: #{body}"  
      SampleGateway.send_mt(sender, receiver, body)
    end
    prompt
  end
  
  def prompt
    print "MT: "
    $stdout.flush
  end
end

class SampleGateway
  
  # MT id counter. 
  @@mt_id = 0
  
  # expose SMPP transceiver's send_mt method
  def self.send_mt(*args)
    @@mt_id += 1
    @@tx.send_mt(@@mt_id, *args)
  end
    
  def logger
    Smpp::Base.logger
  end

  def start(config)
    # The transceiver sends MT messages to the SMSC. It needs a storage with Hash-like
    # semantics to map SMSC message IDs to your own message IDs.
    pdr_storage = {} 

    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    puts "Connecting to SMSC..."
    loop do
      EventMachine::run do             
        @@tx = EventMachine::connect(
          config[:host], 
          config[:port], 
          Smpp::Transceiver, 
          config, 
          self    # delegate that will receive callbacks on MOs and DRs and other events
        )     
        print "MT: "
        $stdout.flush
        
        # Start consuming MT messages (in this case, from the console)
        # Normally, you'd hook this up to a message queue such as Starling
        # or ActiveMQ via STOMP.
        EventMachine::open_keyboard(KeyboardHandler)
      end
      puts "Disconnected. Reconnecting in 5 seconds.."
      sleep 5
    end
  end
  
  # ruby-smpp delegate methods 

  def mo_received(transceiver, pdu)
    logger.info "Delegate: mo_received: from #{pdu.source_addr} to #{pdu.destination_addr}: #{pdu.short_message}"
  end

  def delivery_report_received(transceiver, pdu)
    logger.info "Delegate: delivery_report_received: ref #{pdu.msg_reference} stat #{pdu.stat}"
  end

  def message_accepted(transceiver, mt_message_id, pdu)
    logger.info "Delegate: message_accepted: id #{mt_message_id} smsc ref id: #{pdu.message_id}"
  end

  def message_rejected(transceiver, mt_message_id, pdu)
    logger.info "Delegate: message_rejected: id #{mt_message_id} smsc ref id: #{pdu.message_id}"
  end

  def bound(transceiver)
    logger.info "Delegate: transceiver bound"
  end

  def unbound(transceiver)  
    logger.info "Delegate: transceiver unbound"
    EventMachine::stop_event_loop
  end
  
end

# Start the Gateway
begin   
  puts "Starting SMS Gateway. Please check the log at #{LOGFILE}"  

  # SMPP properties. These parameters work well with the Logica SMPP simulator.
  # Consult the SMPP spec or your mobile operator for the correct settings of 
  # the other properties.
  config = {
    :host => '127.0.0.1',
    :port => 6000,
    :system_id => 'hugo',
    :password => 'ggoohu',
    :system_type => '', # default given according to SMPP 3.4 Spec
    :interface_version => 52,
    :source_ton  => 0,
    :source_npi => 1,
    :destination_ton => 1,
    :destination_npi => 1,
    :source_address_range => '',
    :destination_address_range => '',
    :enquire_link_delay_secs => 10
  }  
  gw = SampleGateway.new
  gw.start(config)  
rescue Exception => ex
  puts "Exception in SMS Gateway: #{ex} at #{ex.backtrace.join("\n")}"
end
