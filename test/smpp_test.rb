require 'rubygems'
require 'test/unit'
require 'smpp'
require 'server'
require 'delegate'
require 'responsive_delegate'

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
