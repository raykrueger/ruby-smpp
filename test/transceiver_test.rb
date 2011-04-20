require "rubygems"
require "test/unit"
require File.expand_path(File.dirname(__FILE__) + "../../lib/smpp")

class TransceiverTest < Test::Unit::TestCase
  def test_get_message_part_size_8
    options = {:data_coding => 8}
    assert_equal(67, Smpp::Transceiver.get_message_part_size(options))
  end
  def test_get_message_part_size_0_and_1
    options = {:data_coding => 0}
    assert_equal(153, Smpp::Transceiver.get_message_part_size(options))
    options = {:data_coding => 1}
    assert_equal(153, Smpp::Transceiver.get_message_part_size(options))
  end
  def test_get_message_part_size_nil
    options = {}
    assert_equal(153, Smpp::Transceiver.get_message_part_size(options))
  end
  def test_get_message_part_size_other
    options = {:data_coding => 3}
    assert_equal(134, Smpp::Transceiver.get_message_part_size(options))
    options = {:data_coding => 5}
    assert_equal(134, Smpp::Transceiver.get_message_part_size(options))
    options = {:data_coding => 6}
    assert_equal(134, Smpp::Transceiver.get_message_part_size(options))
    options = {:data_coding => 7}
    assert_equal(134, Smpp::Transceiver.get_message_part_size(options))
  end
  def test_get_message_part_size_non_existant_data_coding
    options = {:data_coding => 666} 
    assert_equal(153, Smpp::Transceiver.get_message_part_size(options))
  end
end

