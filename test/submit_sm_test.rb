require 'rubygems'
require 'test/unit'
require 'smpp'

class SubmitSmTest < Test::Unit::TestCase

  def test_this_is_not_a_real_test
    value = [383 >> 8, 383 & 0xff]
    optionals = {0x2150 => Smpp::OptionalParameter.new(0x2150, value.pack('cc'))}
    pdu = Smpp::Pdu::SubmitSm.new('12345', '54321', "Ba Ba Boosh", {:optional_parameters => optionals})
    Smpp::Base.hex_debug(pdu.data)
    puts "PDU DATA", pdu.data.inspect
    
  end

  def test_fixnum_optional_parameter
    value = [383 >> 8, 383 & 0xff]
    optionals = {0x2150 => Smpp::OptionalParameter.new(0x2150, value.pack('cc'))}

    pdu = Smpp::Pdu::SubmitSm.new('12345', '54321', "Ba Ba Boosh", {:optional_parameters => optionals})
    pdu_from_wire = Smpp::Pdu::Base.create(pdu.data)

    assert optional = pdu_from_wire.optional_parameters[0x2150]
    
    optional_value = optional[:value].unpack('n')[0]
    assert_equal 383, optional_value
  end

  def test_string_optional_parameter
    optionals = {0x2150 => Smpp::OptionalParameter.new(0x2150, "boosh")}

    pdu = Smpp::Pdu::SubmitSm.new('12345', '54321', "Ba Ba Boosh", {:optional_parameters => optionals})
    pdu_from_wire = Smpp::Pdu::Base.create(pdu.data)

    assert optional = pdu_from_wire.optional_parameters[0x2150]
    
    optional_value = optional[:value].unpack("A*")[0]
    assert_equal 'boosh', optional_value
  end
end
