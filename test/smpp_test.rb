$:.unshift File.dirname(__FILE__) + '/../lib/'

require 'rubygems'
require 'test/unit'
require 'smpp'

# a server which immediately requests the client to unbind
module Server
  def self.config
    {
      :host => 'localhost',
      :port => 2775,
      :system_id => 'foo',
      :password => 'bar',
      :system_type => '',
      :source_ton  => 0,
      :source_npi => 1,
      :destination_ton => 1,
      :destination_npi => 1,
      :source_address_range => '',
      :destination_address_range => ''
    }
  end

  module Unbind
    def receive_data(data)
      send_data Smpp::Pdu::Unbind.new.data
    end
  end

  module SubmitSmResponse
    def receive_data(data)
      # problem: our Pdu's should have factory methods for "both ways"; ie. when created
      # by client, and when created from wire data.
      send_data Smpp::Pdu::SubmitSmResponse.new(1, 2, "100").data
    end
  end

  module SubmitSmResponseWithErrorStatus
    attr_reader :state #state=nil => bind => state=bound => send =>state=sent => unbind => state=unbound
    def receive_data(data)
      if @state.nil?
        @state = 'bound'
        pdu = Smpp::Pdu::Base.create(data)
        response_pdu = Smpp::Pdu::BindTransceiverResponse.new(pdu.sequence_number,Smpp::Pdu::Base::ESME_ROK,Server::config[:system_id])
        send_data response_pdu.data
      elsif @state == 'bound'
        @state = 'sent'
        pdu = Smpp::Pdu::Base.create(data)
        pdu.to_human
        send_data Smpp::Pdu::SubmitSmResponse.new(pdu.sequence_number, Smpp::Pdu::Base::ESME_RINVDSTADR, pdu.body).data
        #send_data Smpp::Pdu::SubmitSmResponse.new(1, 2, "100").data
      elsif @state == 'sent'
        @state = 'unbound'
        send_data Smpp::Pdu::Unbind.new.data
      else
        raise "unexpected state"
      end
    end
  end

end


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

class Poller
  def start
    
  end
end


class SmppTest < Test::Unit::TestCase
  
  def config
    Server::config
  end
  
  def test_transceiver_should_bind_and_unbind_then_stop
    EventMachine.run {
      EventMachine.start_server "localhost", 9000, Server::Unbind
      EventMachine.connect "localhost", 9000, Smpp::Transceiver, config, Delegate.new
    }
    # should not hang here: the server's response should have caused the client to terminate
  end

  def test_transceiver_api_should_respond_to_message_rejected
    $tx = nil
    delegate = ResponsiveDelegate.new
    EventMachine.run {
      EventMachine.start_server "localhost", 9000, Server::SubmitSmResponseWithErrorStatus
      $tx = EventMachine.connect "localhost", 9000, Smpp::Transceiver, config, delegate
    }
    assert_equal(delegate.event_counter[:message_rejected], 1)
  end

  def test_bind_transceiver
    pdu1 = Smpp::Pdu::BindTransceiver.new(
      config[:system_id],
      config[:password],
      config[:system_type],
      config[:source_ton],
      config[:source_npi],
      config[:source_address_range]
    )

    pdu2 = Smpp::Pdu::Base.create(pdu1.data)

    assert_instance_of(Smpp::Pdu::BindTransceiver, pdu2)
    assert_equal(pdu1.system_id, pdu2.system_id)
    assert_equal(pdu1.password, pdu2.password)
    assert_equal(pdu1.system_type, pdu2.system_type)
    assert_equal(pdu1.addr_ton, pdu2.addr_ton)
    assert_equal(pdu1.addr_npi, pdu2.addr_npi)
    assert_equal(pdu1.address_range, pdu2.address_range)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_bind_transceiver_response
    pdu1 = Smpp::Pdu::BindTransceiverResponse.new(nil, Smpp::Pdu::Base::ESME_ROK, config[:system_id])
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::BindTransceiverResponse, pdu2)
    assert_equal(pdu1.system_id, pdu2.system_id)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_deliver_sm
    pdu1 = Smpp::Pdu::DeliverSm.new( '11111', '1111111111', "This is a test" )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::DeliverSm, pdu2)
    assert_equal(pdu1.udh, pdu2.udh)
    assert_equal(pdu1.short_message, pdu2.short_message)
    assert_equal(pdu1.service_type, pdu2.service_type)
    assert_equal(pdu1.source_addr_ton, pdu2.source_addr_ton)
    assert_equal(pdu1.source_addr_npi, pdu2.source_addr_npi)
    assert_equal(pdu1.source_addr, pdu2.source_addr)
    assert_equal(pdu1.dest_addr_ton, pdu2.dest_addr_ton)
    assert_equal(pdu1.dest_addr_npi, pdu2.dest_addr_npi)
    assert_equal(pdu1.destination_addr, pdu2.destination_addr)
    assert_equal(pdu1.esm_class, pdu2.esm_class)
    assert_equal(pdu1.protocol_id, pdu2.protocol_id)
    assert_equal(pdu1.priority_flag, pdu2.priority_flag)
    assert_equal(pdu1.schedule_delivery_time, pdu2.schedule_delivery_time)
    assert_equal(pdu1.validity_period, pdu2.validity_period)
    assert_equal(pdu1.registered_delivery, pdu2.registered_delivery)
    assert_equal(pdu1.replace_if_present_flag, pdu2.replace_if_present_flag)
    assert_equal(pdu1.data_coding, pdu2.data_coding)
    assert_equal(pdu1.sm_default_msg_id, pdu2.sm_default_msg_id)
    assert_equal(pdu1.sm_length, pdu2.sm_length)
    assert_equal(pdu1.stat, pdu2.stat)
    assert_equal(pdu1.msg_reference, pdu2.msg_reference)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_submit_sm
    pdu1 = Smpp::Pdu::SubmitSm.new( '11111', '1111111111', "This is a test" )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::SubmitSm, pdu2)
    assert_equal(pdu1.udh, pdu2.udh)
    assert_equal(pdu1.short_message, pdu2.short_message)
    assert_equal(pdu1.service_type, pdu2.service_type)
    assert_equal(pdu1.source_addr_ton, pdu2.source_addr_ton)
    assert_equal(pdu1.source_addr_npi, pdu2.source_addr_npi)
    assert_equal(pdu1.source_addr, pdu2.source_addr)
    assert_equal(pdu1.dest_addr_ton, pdu2.dest_addr_ton)
    assert_equal(pdu1.dest_addr_npi, pdu2.dest_addr_npi)
    assert_equal(pdu1.destination_addr, pdu2.destination_addr)
    assert_equal(pdu1.esm_class, pdu2.esm_class)
    assert_equal(pdu1.protocol_id, pdu2.protocol_id)
    assert_equal(pdu1.priority_flag, pdu2.priority_flag)
    assert_equal(pdu1.schedule_delivery_time, pdu2.schedule_delivery_time)
    assert_equal(pdu1.validity_period, pdu2.validity_period)
    assert_equal(pdu1.registered_delivery, pdu2.registered_delivery)
    assert_equal(pdu1.replace_if_present_flag, pdu2.replace_if_present_flag)
    assert_equal(pdu1.data_coding, pdu2.data_coding)
    assert_equal(pdu1.sm_default_msg_id, pdu2.sm_default_msg_id)
    assert_equal(pdu1.sm_length, pdu2.sm_length)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_submit_sm_receiving_invalid_status
    pdu1 = Smpp::Pdu::SubmitSm.new( '11111', '1111111111', "This is a test" )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
  end

  def test_deliver_sm_response
    pdu1 = Smpp::Pdu::DeliverSmResponse.new( nil )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::DeliverSmResponse, pdu2)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_submit_sm_response
    pdu1 = Smpp::Pdu::SubmitSmResponse.new( nil, Smpp::Pdu::Base::ESME_ROK, 3 )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::SubmitSmResponse, pdu2)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_enquire_link
    pdu1 = Smpp::Pdu::EnquireLink.new( )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::EnquireLink, pdu2)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_enquire_link_resp
    pdu1 = Smpp::Pdu::EnquireLinkResponse.new( )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::EnquireLinkResponse, pdu2)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end
    
  def test_generic_nack
    pdu1 = Smpp::Pdu::GenericNack.new(nil, Smpp::Pdu::Base::ESME_RTHROTTLED )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::GenericNack, pdu2)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_unbind
    pdu1 = Smpp::Pdu::Unbind.new()
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::Unbind, pdu2)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def test_unbind_response
    pdu1 = Smpp::Pdu::UnbindResponse.new(nil, Smpp::Pdu::Base::ESME_ROK)
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::UnbindResponse, pdu2)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  #TODO: This test is known to fail since this portion of the library is incomplete.
  def _todo_test_submit_multi 
    pdu1 = Smpp::Pdu::SubmitMulti.new( '11111', ['1111111111','1111111112','1111111113'], "This is a test" )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    assert_instance_of(Smpp::Pdu::SubmitMulti, pdu2)
    assert_equal(pdu1.udh, pdu2.udh)
    assert_equal(pdu1.short_message, pdu2.short_message)
    assert_equal(pdu1.service_type, pdu2.service_type)
    assert_equal(pdu1.source_addr_ton, pdu2.source_addr_ton)
    assert_equal(pdu1.source_addr_npi, pdu2.source_addr_npi)
    assert_equal(pdu1.source_addr, pdu2.source_addr)
    assert_equal(pdu1.dest_addr_ton, pdu2.dest_addr_ton)
    assert_equal(pdu1.dest_addr_npi, pdu2.dest_addr_npi)
    assert_equal(pdu1.destination_addr_array, pdu2.destination_addr_array)
    assert_equal(pdu1.esm_class, pdu2.esm_class)
    assert_equal(pdu1.protocol_id, pdu2.protocol_id)
    assert_equal(pdu1.priority_flag, pdu2.priority_flag)
    assert_equal(pdu1.schedule_delivery_time, pdu2.schedule_delivery_time)
    assert_equal(pdu1.validity_period, pdu2.validity_period)
    assert_equal(pdu1.registered_delivery, pdu2.registered_delivery)
    assert_equal(pdu1.replace_if_present_flag, pdu2.replace_if_present_flag)
    assert_equal(pdu1.data_coding, pdu2.data_coding)
    assert_equal(pdu1.sm_default_msg_id, pdu2.sm_default_msg_id)
    assert_equal(pdu1.sm_length, pdu2.sm_length)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end

  def _test_submit_multi_response
    smes = [
      Smpp::Pdu::SubmitMultiResponse::UnsuccessfulSme.new(1,1,'1111111111',  Smpp::Pdu::Base::ESME_RINVDSTADR),
      Smpp::Pdu::SubmitMultiResponse::UnsuccessfulSme.new(1,1,'1111111112',  Smpp::Pdu::Base::ESME_RINVDSTADR),
      Smpp::Pdu::SubmitMultiResponse::UnsuccessfulSme.new(1,1,'1111111113',  Smpp::Pdu::Base::ESME_RINVDSTADR),
    ]
    pdu1 = Smpp::Pdu::SubmitMultiResponse.new( nil, Smpp::Pdu::Base::ESME_ROK, '3', smes )
    pdu2 = Smpp::Pdu::Base.create(pdu1.data)
    
    assert_instance_of(Smpp::Pdu::SubmitMultiResponse, pdu2)
    assert_equal(pdu1.unsuccess_smes, pdu2.unsuccess_smes)
    assert_equal(pdu1.sequence_number, pdu2.sequence_number)
    assert_equal(pdu1.command_status, pdu2.command_status)
  end
  
  def test_should_parse_ref_and_stat_from_deliver_sm
    direct = Smpp::Pdu::DeliverSm.new( '1', '2', "419318028472222#id:11f8f46639bd4f7a209016e1a181e3ae sub:001 dlvrd:001 submit date:0902191702 done date:0902191702 stat:DELIVRD err:000 Text:TVILLING: Sl? ut h?'!11f8f46639bd4f7a209016e1a181e3ae", :esm_class => 4)
    parsed = Smpp::Pdu::Base.create(direct.data)
    assert_equal("DELIVRD", parsed.stat)
    assert_equal("11f8f46639bd4f7a209016e1a181e3ae", parsed.msg_reference)
  end
  

end
