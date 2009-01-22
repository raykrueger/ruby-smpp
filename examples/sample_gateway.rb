#!/usr/bin/env ruby0
LOGFILE = File.dirname(__FILE__) + "/sms_gateway.log"
Smpp::Base.logger = Logger.new(LOGFILE)

# the transceiver
$tx = nil

# We use EventMachine to receive keyboard input (which we send as MT messages).
# A "real" gateway would probably get its MTs from a message queue instead.
module KeyboardHandler
  include EventMachine::Protocols::LineText2

  def receive_line(data)
    puts "Sending MT: #{data}"
    from = '2210'
    to = '4790000000'     
    msg_id = 123  
    $tx.send_mt(msg_id, from, to, data)


    # if you want to send messages with custom options, uncomment below code, this configuration allows the sender ID to be alpha numeric
    #    $tx.send_mt(123, "RubySmpp", to, "Testing RubySmpp as sender id",{
    #    :source_addr_ton=> 5,
    #	:service_type => 1,
    #	:source_addr_ton => 5,
    #	:source_addr_npi => 0 ,
    #	:dest_addr_ton => 2, 
    #	:dest_addr_npi => 1, 
    #	:esm_class => 3 ,
    #	:protocol_id => 0, 
    #	:priority_flag => 0,
    #	:schedule_delivery_time => nil,
    #	:validity_period => nil,
    #	:registered_delivery=> 1,
    #	:replace_if_present_flag => 0,
    #	:data_coding => 0,
    #	:sm_default_msg_id => 0 
    #     })   

    # if you want to send message to multiple destinations , uncomment below code
    #    $tx.send_multi_mt(123, from, ["919900000001","919900000002","919900000003"], "I am echoing that ruby-smpp is great")  
    prompt
  end
  
  def prompt
    print "Enter MT body: "
    $stdout.flush
  end
end

class SampleGateway
  include KeyboardHandler
  
  def logger
    Smpp::Base.logger
  end

  def start(config)
    # The transceiver sends MT messages to the SMSC. It needs a storage with Hash-like
    # semantics to map SMSC message IDs to your own message IDs.
    pdr_storage = {} 

    # The block invoked when we receive an MO message from the SMSC
    mo_proc = Proc.new do |sender, receiver, msg|
      begin
        # This is where you'd enqueue or store the MO message for further processing.
        logger.info "Received MO from <#{sender}> to <#{receiver}>: <#{msg}>"
      rescue Exception => ex
        logger.error "Exception processing MO: #{ex}"
      end
    end

    # Invoked on delivery reports
    dr_proc = Proc.new do |msg_reference, stat, dr_pdu|
      begin
        # The SMSC returns its own message reference. Look up (and delete) our stored objects
        # based on this reference.
        # 
        # The short_message attribute contains details on the current delivery status of the
        # message.
        pending_message = pdr_storage.delete(msg_reference)
        logger.info "Received DR for #{pending_message}. Stat: #{stat} SM: #{dr_pdu.short_message}"
      rescue Exception => ex
        logger.error "Error processing DR: #{ex}"
      end
    end

    # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
    prompt
    loop do
      EventMachine::run do             
        $tx = EventMachine::connect(
        config[:host], 
        config[:port], 
        Smpp::Transceiver, 
        config, 
        self  # self is delegate
        )     

        # Start consuming MT messages (in this case, from the console)
        # Normally, you'd hook this up to a message queue such as Starling
        # or ActiveMQ via STOMP.
        EventMachine::open_keyboard(KeyboardHandler)
      end
      logger.warn "Event loop stopped. Restarting in 5 seconds.."
      sleep 5
    end

  end
  # Delegate methods that will receive callbacks on various events

  def mo_received(transceiver, source_addr, destination_addr, short_message)
    logger.info "Delegate: mo_received: from #{source_addr} to #{destination_addr}: #{short_message}"
  end

  def delivery_report_received(transceiver, msg_reference, stat, pdu)
    logger.info "Delegate: delivery_report_received: ref #{msg_reference} stat #{stat} pdu #{pdu}"
  end

  def message_accepted(transceiver, mt_message_id, smsc_message_id)
    logger.info "Delegate: message_sent: id #{mt_message_id} smsc ref id: #{smsc_message_id}"
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
  puts "Starting SMS Gateway. Check the log at #{LOGFILE}"  

  # SMPP properties. These parameters work well with the Logica SMPP simulator.
  # Consult the SMPP spec or your mobile operator for the correct settings of 
  # the other properties.
  config = {
    :host => 'localhost',
    :port => 6000,
    :system_id => 'hugo',
    :password => 'ggoohu',
    :system_type => 'vma', # default given according to SMPP 3.4 Spec
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
