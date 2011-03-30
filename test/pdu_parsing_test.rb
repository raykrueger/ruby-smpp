require 'rubygems'
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "../../lib/smpp")

class PduParsingTest < Test::Unit::TestCase

  def test_recieve_single_message
    raw_data = <<-EOF
    0000 003d 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3830 3330 3239 3833 3700
    0101 3434 3738 3033 3032 3938 3337 0000
    0000 0000 0000 0000 0454 6573 74
    EOF

    pdu = create_pdu(raw_data)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal "447803029837", pdu.source_addr
    assert_equal "447803029837", pdu.destination_addr
    assert_nil pdu.udh
    assert_equal "Test", pdu.short_message
  end

  def test_recieve_part_one_of_multi_part_message
    part_one_message = <<-EOF
    0000 00d8 0000 0005 0000 0000 0000 0001
    0001 0134 3437 3937 3334 3238 3634 3400
    0101 3434 3739 3736 3232 3430 3137 0000
    0000 0000 0000 0000 9f05 0003 b402 0154
    6869 7320 6973 2061 206c 6f6e 6720 6d65
    7373 6167 6520 746f 2074 6573 7420 7768
    6574 6865 7220 6f72 206e 6f74 2077 6520
    6765 7420 7468 6520 6865 6164 6572 2069
    6e66 6f20 7669 6120 7468 6520 534d 5343
    2074 6861 7420 7765 2077 6f75 6c64 2072
    6571 7569 7265 2074 6f20 6265 2061 626c
    6520 746f 2072 6563 6f6d 706f 7365 206c
    6f6e 6720 6d65 7373 6167 6573 2069 6e20
    6861 7368 626c 7565
    EOF

    pdu = create_pdu(part_one_message)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal "447973428644", pdu.source_addr
    assert_equal "447976224017", pdu.destination_addr
    assert_equal [5, 0, 3, 180, 2, 1], pdu.udh

    assert_equal 2, pdu.total_parts, "Have total parts of the message"
    assert_equal 1, pdu.part, "Correctly show the part"
    assert_equal 180, pdu.message_id

    assert_equal "This is a long message to test whether or not we get the header info via the SMSC that we would require to be able to recompose long messages in hashblue", pdu.short_message
  end

  def test_recieve_part_two_of_multi_part_message
    part_two_message = <<-EOF
    0000 0062 0000 0005 0000 0000 0000 0002
    0001 0134 3437 3937 3334 3238 3634 3400
    0101 3434 3739 3736 3232 3430 3137 0000
    0000 0000 0000 0000 2905 0003 b402 0220
    616e 6420 7072 6f76 6964 6520 6120 676f
    6f64 2075 7365 7220 6578 7065 7269 656e
    6365
    EOF

    pdu = create_pdu(part_two_message)
    assert_equal Smpp::Pdu::DeliverSm, pdu.class
    assert_equal "447973428644", pdu.source_addr
    assert_equal "447976224017", pdu.destination_addr
    assert_equal [5, 0, 3, 180, 2, 2], pdu.udh

    assert_equal 2, pdu.total_parts, "Have total parts of the message"
    assert_equal 2, pdu.part, "Correctly show the part"
    assert_equal 180, pdu.message_id

    assert_equal " and provide a good user experience", pdu.short_message
  end

  protected
  def create_pdu(raw_data)
    hex_data = [raw_data.chomp.gsub(" ","").gsub(/\n/,"")].pack("H*")
    Smpp::Pdu::Base.create(hex_data)
  end

end