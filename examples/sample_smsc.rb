#!/usr/bin/env ruby

# Sample SMPP SMS Gateway. 

require 'rubygems'
require File.dirname(__FILE__) + '/../lib/smpp'
require File.dirname(__FILE__) + '/../lib/smpp/server'

# set up logger
Smpp::Base.logger = Logger.new('smsc.log')

# the transceiver
$tx = nil

# We use EventMachine to receive keyboard input (which we send as MT messages).
# A "real" gateway would probably get its MTs from a message queue instead.
module KeyboardHandler
  include EventMachine::Protocols::LineText2

  def receive_line(data)
    puts "Sending MO: #{data}"
    from = '1111111111'
    to = '1111111112'       
    $tx.send_mo(from, to, data)


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
end

def prompt
  print "Enter MO body: "
  $stdout.flush
end

def logger
  Smpp::Base.logger
end

def start(config)

  # Run EventMachine in loop so we can reconnect when the SMSC drops our connection.
  loop do
    EventMachine::run do             
      $tx = EventMachine::start_server(
          config[:host], 
          config[:port], 
          Smpp::Server,
          config
          )       
    end
    logger.warn "Event loop stopped. Restarting in 5 seconds.."
    sleep 5
  end
end

# Start the Gateway
begin   
  puts "Starting SMS Gateway"  

  # SMPP properties. These parameters the ones provided sample_gateway.rb and
  # will work with it.
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
  start(config)  
rescue Exception => ex
  puts "Exception in SMS Gateway: #{ex} at #{ex.backtrace[0]}"
end
