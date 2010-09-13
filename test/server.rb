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
