$:.unshift File.dirname(__FILE__) + '/../lib/'

require 'test/unit'
require 'stringio'
require 'smpp'

module Server1
  def receive_data(data)        
    send_data Smpp::Pdu::Unbind.new.data    
  end
end

module Server2
  def receive_data(data)
    # problem: our Pdu's should have factory methods for "both ways"; ie. when created 
    # by client, and when created from wire data.
    send_data Smpp::Pdu::SubmitSmResponse.new(1, 2, "100").data
  end
end

class SmppTest < Test::Unit::TestCase
  
  def config
    {
      :host => 'localhost',
      :port => 2775,
      :system_id => 'foo',
      :password => 'bar',
      :source_ton  => 0,
      :source_npi => 1,
      :destination_ton => 1,
      :destination_npi => 1,
      :source_address_range => '',
      :destination_address_range => ''
    }
  end
  
  def test_transceiver_should_bind_and_unbind_and_stop
    EventMachine.run {
      EventMachine.start_server "localhost", 9000, Server1
      EventMachine.connect "localhost", 9000, Smpp::Transceiver, config, nil, nil
    }
    # should not hang here: the server's response should have caused the client to terminate
  end
  
  def ____test_transceiver_should_send_mt
    EventMachine.run {
      EventMachine.start_server "localhost", 9000, Server2
      EventMachine.connect "localhost", 9000, Smpp::Transceiver, config, nil, nil
    }
    # should not hang here: the server's response should have caused the client to terminate
  end
  
end
