#!/usr/bin/env ruby

# Sample SMPP SMS Gateway. 

require 'rubygems'
require File.dirname(__FILE__) + '/../lib/smpp'

Smpp::Base.logger = Logger.new('smsc.log')

class Play
  def unbound(connection)
    connection.logger.info "Delegate: Transmitter unbound"
    EventMachine::stop_event_loop
  end

  def bound(connection)
    connection.send_mt(1, "44816505591", "44816505591", "Test message sending from Hashblue")
  end

  def start
    smpp_config = {
      :host                    => 'localhost',
      :port                    => 8100,
      :system_id               => 'system_id',
      :password                => 'password',
      #:received_messages       => config['received_messages'],
      :system_type             => '',
      :source_ton              => 0,
      :source_npi              => 1,
      :source_address_range    => '',
      :enquire_link_delay_secs => 10,
      :reconnect_delay         => 60
    }
    
    loop do
      EventMachine::run do
        transmitter = EventMachine::connect(
          smpp_config[:host],
          smpp_config[:port],
          Smpp::Transmitter,
          smpp_config,
          self    # delegate that will receive callbacks on MOs and DRs and other events
        )
      end

      Smpp::Base.logger.info "Disconnected. Reconnecting in #{smpp_config[:reconnect_delay]} seconds.."
      sleep smpp_config[:reconnect_delay]
    end
  end
end

Play.new.start