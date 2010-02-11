require 'rubygems'
require 'test/unit'
require 'smpp'

class OptionalParameterTest < Test::Unit::TestCase
  include Smpp

  def test_symbol_accessor
    op = OptionalParameter.new(0x2150, "abcd")
    assert_equal "abcd", op[:value]
    assert_equal 0x2150, op[:tag]
  end

  def test_bad_data_does_not_puke
    assert_raise RuntimeError do
      OptionalParameter.from_wire_data("")
    end
  end

  def test_from_wire_data
    data = "\041\120\000\002\001\177"
    op, remaining_data = OptionalParameter.from_wire_data(data)
    assert_not_nil op, "op should not be nil"
    assert_equal 0x2150, op.tag
    assert_equal "\001\177", op.value
    assert_equal "", remaining_data
  end

end

