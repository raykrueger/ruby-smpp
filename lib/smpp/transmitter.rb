# The SMPP Transmitter maintains a unidirectional connection to an SMSC.
# Provide a config hash with connection options to get started.
# See the sample_gateway.rb for examples of config values.

class Smpp::Transmitter < Smpp::Base

  attr_reader :ack_ids

  # Send an MT SMS message. Delegate will receive message_accepted callback when SMSC
  # acknowledges, or the message_rejected callback upon error
  def send_mt(message_id, source_addr, destination_addr, short_message, options={})
    logger.debug "Sending MT: #{short_message}"
    if @state == :bound
      pdu = Pdu::SubmitSm.new(source_addr, destination_addr, short_message, options)
      write_pdu(pdu)

      # keep the message ID so we can associate the SMSC message ID with our message
      # when the response arrives.
      @ack_ids[pdu.sequence_number] = message_id
    else
      raise InvalidStateException, "Transmitter is unbound. Cannot send MT messages."
    end
  end

  def send_concat_mt(message_id, source_addr, destination_addr, message, options = {})
      if @state == :bound
        # Split the message into parts of 134 characters.
        parts = []
        while message.size > 0 do
          parts << message.slice!(0..133)
        end
        0.upto(parts.size-1) do |i|
          udh = sprintf("%c", 5)            # UDH is 5 bytes.
          udh << sprintf("%c%c", 0, 3)      # This is a concatenated message
          udh << sprintf("%c", message_id)  # The ID for the entire concatenated message
          udh << sprintf("%c", parts.size)  # How many parts this message consists of

          udh << sprintf("%c", i+1)         # This is part i+1

          combined_options = {
            :esm_class => 64,               # This message contains a UDH header.
            :udh => udh
          }.merge(options)

          pdu = Smpp::Pdu::SubmitSm.new(source_addr, destination_addr, parts[i], combined_options)
          write_pdu(pdu)
        end
      else
        raise InvalidStateException, "Transmitter is unbound. Cannot send MT messages."
      end
    end

  def send_bind
    raise IOError, 'Transmitter already bound.' unless unbound?
    pdu = Pdu::BindTransmitter.new(
        @config[:system_id],
        @config[:password],
        @config[:system_type],
        @config[:source_ton],
        @config[:source_npi],
        @config[:source_address_range])
    write_pdu(pdu)
  end
end
