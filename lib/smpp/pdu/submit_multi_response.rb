# Recieving response for an MT message sent to multiple addresses
# Author: Abhishek Parolkar, (abhishek[at]parolkar.com)
class Smpp::Pdu::SubmitMultiResponse < Smpp::Pdu::Base
  class UnsuccessfulSme 
    Struct.new(:dest_addr_ton, :dest_addr_npi, :destination_addr, :error_status_code)
  end

  handles_cmd SUBMIT_MULTI_RESP

  attr_accessor :message_id, :unsuccess_smes

  def initialize(seq, status, message_id, unsuccess_smes = [])
    @unsuccess_smes = unsuccess_smes
    seq ||= next_sequence_number

    packed_smes = ""
    unsuccess_smes.each do |sme|
      packed_smes << [
        sme.dest_addr_ton, 
        sme.dest_addr_npi, 
        sme.destination_addr, 
        sme.error_status_code
      ].pack("CCZ*N")
    end
    body = [message_id, unsuccess_smes.size, packed_smes].pack("Z*Ca*")

    super(SUBMIT_MULTI_RESP, status, seq, body)
    @message_id = message_id
  end

  def self.from_wire_data(seq, status, body)
    message_id, no_unsuccess, rest = body.unpack("Z*Ca*")
    unsuccess_smes = []

    no_unsuccess.times do |i|
      #unpack the next sme
      dest_addr_ton, dest_addr_npi, destination_addr, error_status_code =
        rest.unpack("CCZ*N")
      #remove the SME from rest 
      rest.slice!(0,7 + destination_addr.length)
      unsuccess_smes << UnsuccessfulSme.new(dest_addr_ton, dest_addr_npi, destination_addr, error_status_code)
    end
    
    new(seq, status, message_id, unsuccess_smes)
  end



end    
