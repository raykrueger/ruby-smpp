# SMPP v3.4 subset implementation.
# SMPP is a short message peer-to-peer protocol typically used to communicate 
# with SMS Centers (SMSCs) over TCP/IP.
#
# August Z. Flatby
# august@apparat.no

require 'logger'

$:.unshift(File.dirname(__FILE__))
require 'smpp/base.rb'
require 'smpp/transceiver.rb'
require 'smpp/receiver.rb'
require 'smpp/optional_parameter'
require 'smpp/pdu/base.rb'
require 'smpp/pdu/bind_base.rb'
require 'smpp/pdu/bind_resp_base.rb'

# Load all PDUs
Dir.glob(File.join(File.dirname(__FILE__), 'smpp', 'pdu', '*.rb')) do |f|
  require f unless f.match('base.rb$')
end

# Default logger. Invoke this call in your client to use another logger.
Smpp::Base.logger = Logger.new(STDOUT)
