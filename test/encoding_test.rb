require 'rubygems'
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "../../lib/smpp")

class EncodingTest < Test::Unit::TestCase

  def test_should_decode_pound_sign_from_hp_roman_8_to_utf_8
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 2950 6C65 6173 6520
    6465 706F 7369 7420 BB35 2069 6E74 6F20
    6D79 2061 6363 6F75 6E74 2C20 4A6F 73C5
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding
    
    expected = "Please deposit \302\2435 into my account, Jos\303\251"
    assert_equal expected, pdu.short_message
  end

  protected
  def create_pdu(raw_data)
    hex_data = [raw_data.chomp.gsub(" ","").gsub(/\n/,"")].pack("H*")
    Smpp::Pdu::Base.create(hex_data)
  end

end