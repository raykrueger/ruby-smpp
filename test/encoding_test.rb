# -*- encoding : utf-8 -*-
require 'rubygems'
require 'test/unit'
require 'smpp/encoding/utf8_encoder'

require File.expand_path(File.dirname(__FILE__) + "../../lib/smpp")

class EncodingTest < Test::Unit::TestCase


  def setup
    ::Smpp::Pdu::DeliverSm.data_encoder = ::Smpp::Encoding::Utf8Encoder.new
  end

  def teardown
    ::Smpp::Pdu::DeliverSm.data_encoder = nil
  end

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

  def test_should_unescape_gsm_escaped_euro_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 1950 6c65 6173 6520
    6465 706f 7369 7420 8d65 3520 7468 616e
    6b73
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    expected = "Please deposit \342\202\2545 thanks"
    assert_equal expected, pdu.short_message
  end

  def test_should_unescape_gsm_escaped_left_curly_bracket_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d 28
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    assert_equal "{", pdu.short_message
  end

  def test_should_unescape_gsm_escaped_right_curly_bracket_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d 29
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    assert_equal "}", pdu.short_message
  end

  def test_should_unescape_gsm_escaped_tilde_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d 3d
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    assert_equal "~", pdu.short_message
  end

  def test_should_unescape_gsm_escaped_left_square_bracket_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d 3c
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    assert_equal "[", pdu.short_message
  end

  def test_should_unescape_gsm_escaped_right_square_bracket_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d 3e
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    assert_equal "]", pdu.short_message
  end

  def test_should_unescape_gsm_escaped_backslash_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d 2f
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    assert_equal "\\", pdu.short_message
  end

  def test_should_unescape_gsm_escaped_vertical_bar_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d b8
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    assert_equal "|", pdu.short_message
  end

  def test_should_unescape_gsm_escaped_caret_or_circumflex_symbol
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 028d 86
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    expected = "\313\206"
    assert_equal expected, pdu.short_message
  end

  def test_should_unescape_gsm_escaped_characters_together
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 4054 6573 748d b869
    6e67 208d 8620 7374 6167 2f69 6e67 208d
    3d20 6575 726f 208d 6520 616e 6420 8d28
    6f74 688d 2f65 7220 8d3c 2063 6861 7261
    8d3e 6374 6572 738d 29
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 0, pdu.data_coding

    expected = "Test|ing ˆ stag/ing ~ euro € and {oth\\er [ chara]cters}"
    assert_equal expected, pdu.short_message
  end

  def test_should_convert_ucs_2_into_utf_8_where_data_coding_indicates_its_presence
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0800 0E00 db00 f100 ef00
    e700 f800 6401 13
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal 8, pdu.data_coding

    expected = "\303\233\303\261\303\257\303\247\303\270d\304\223" # Ûñïçødē
    assert_equal expected, pdu.short_message
  end

  def test_should_decode_pound_sign_from_hp_roman_8_to_utf_8_when_data_coding_set_to_1
    raw_data = <<-EOF
    0000 0096 0000 0005 0000 0000 0000 1b10
    0005 004d 6f6e 6579 416c 6572 7400 0101
    3434 3737 3738 3030 3036 3133 0000 0000
    0000 0000 0100 5fbb 506f 756e 6473 bb20
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal "£Pounds£ ", pdu.short_message
  end

  protected
  def create_pdu(raw_data)
    hex_data = [raw_data.chomp.gsub(" ","").gsub(/\n/,"")].pack("H*")
    Smpp::Pdu::Base.create(hex_data)
  end

end
