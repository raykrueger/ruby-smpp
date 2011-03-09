require 'rubygems'
require 'test/unit'
require 'smpp'

class TransmitterTest < Test::Unit::TestCase

  class RecordingDelegate
    attr_reader :states
    def initialize
      @states = []
    end
    def bound(receiver)
      @states << :bound
    end
  end

  def test_receiving_bind_transmitter_response_with_ok_status_should_become_bound
    transmitter = build_transmitter
    bind_transmitter_response = Smpp::Pdu::BindTransmitterResponse.new(nil, Smpp::Pdu::Base::ESME_ROK, 1)

    transmitter.process_pdu(bind_transmitter_response)

    assert transmitter.bound?
  end

  def test_receiving_bind_transmitter_response_with_ok_status_should_invoke_bound_on_delegate
    delegate = RecordingDelegate.new
    transmitter = build_transmitter(delegate)
    bind_transmitter_response = Smpp::Pdu::BindTransmitterResponse.new(nil, Smpp::Pdu::Base::ESME_ROK, 1)

    transmitter.process_pdu(bind_transmitter_response)

    assert_equal [:bound], delegate.states
  end

  def test_receiving_bind_transmitter_response_with_ok_status_should_not_error_if_method_doesnt_exist_on_delegate
    delegate = Object.new
    transmitter = build_transmitter(delegate)
    bind_transmitter_response = Smpp::Pdu::BindTransmitterResponse.new(nil, Smpp::Pdu::Base::ESME_ROK, 1)

    assert_nothing_raised { transmitter.process_pdu(bind_transmitter_response) }
  end

  def test_receiving_bind_transmitter_response_with_error_status_should_not_become_bound
    transmitter = build_transmitter
    bind_transmitter_response = Smpp::Pdu::BindTransmitterResponse.new(nil, Smpp::Pdu::Base::ESME_RBINDFAIL, 1)

    transmitter.process_pdu(bind_transmitter_response)

    assert transmitter.unbound?
  end

  def test_receiving_bind_transmitter_response_with_error_status_should_not_invoke_bound_on_delegate
    delegate = RecordingDelegate.new
    transmitter = build_transmitter(delegate)
    bind_transmitter_response = Smpp::Pdu::BindTransmitterResponse.new(nil, Smpp::Pdu::Base::ESME_RBINDFAIL, 1)

    transmitter.process_pdu(bind_transmitter_response)

    assert_equal [], delegate.states
  end

  def test_transmitter_bind_receiver_response_with_error_status_should_close_connection
    transmitter = build_transmitter
    bind_transmitter_response = Smpp::Pdu::BindTransmitterResponse.new(nil, Smpp::Pdu::Base::ESME_RBINDFAIL, 1)

    transmitter.process_pdu(bind_transmitter_response)

    assert_equal 1, transmitter.close_connections
  end

  def test_receiving_submit_sm_response_with_ok_status_should_log_debug_message_to_indicate_success
    delegate = RecordingDelegate.new
    transmitter = build_transmitter(delegate)
    submit_sm_response = Smpp::Pdu::SubmitSmResponse.new(nil, Smpp::Pdu::Base::ESME_ROK, 1)
    io = StringIO.new
    transmitter.with_logger(Logger.new(io)) do
      transmitter.process_pdu(submit_sm_response)
    end
    io.rewind
    assert_match %r{Received SubmitSmResponse successfully}, io.read
  end

  def test_receiving_submit_sm_response_with_non_ok_status_should_log_debug_message_to_indicate_failure
    delegate = RecordingDelegate.new
    transmitter = build_transmitter(delegate)
    submit_sm_response = Smpp::Pdu::SubmitSmResponse.new(nil, Smpp::Pdu::Base::ESME_RSUBMITFAIL, 1)
    io = StringIO.new
    transmitter.with_logger(Logger.new(io)) do
      transmitter.process_pdu(submit_sm_response)
    end
    io.rewind
    assert_match %r{Received SubmitSmResponse failed}, io.read
  end

  def test_raise_exception_if_transmitter_is_not_bound_when_we_attempt_to_send_a_message
    transmitter = build_transmitter
    assert_raises(Smpp::InvalidStateException) do
      transmitter.send_mt(1, "07700900123", "07700900456", "Well, do ya, punk?")
    end
  end

  def test_send_submit_sm_pdu_when_we_attempt_to_send_a_message
    transmitter = build_transmitter
    bind_transmitter_response = Smpp::Pdu::BindTransmitterResponse.new(nil, Smpp::Pdu::Base::ESME_ROK, 1)
    transmitter.process_pdu(bind_transmitter_response)

    transmitter.send_mt(1, "07700900123", "07700900456", "Well, do ya, punk?")
    
    first_sent_data = transmitter.sent_data.first
    assert_not_nil first_sent_data
    actual_pdu = Smpp::Pdu::Base.create(first_sent_data)
    expected_pdu = Smpp::Pdu::SubmitSm.new("07700900123", "07700900456", "Well, do ya, punk?", {}, 1)
    assert_equal expected_pdu.to_human, actual_pdu.to_human
  end

  private

  def build_transmitter(delegate = nil)
    transmitter = Smpp::Transmitter.new(1, {}, delegate)
    class << transmitter
      attr_reader :sent_data, :close_connections
      def send_data(data)
        @sent_data = (@sent_data || []) + [data]
      end
      def close_connection
        @close_connections = (@close_connections || 0) + 1
      end
      def with_logger(temporary_logger)
        original = Smpp::Base.logger
        begin
          Smpp::Base.logger = temporary_logger
          yield
        ensure
          Smpp::Base.logger = original
        end
      end
    end
    transmitter
  end

end
