= Ruby-SMPP

== DESCRIPTION:

Ruby-SMPP is a Ruby implementation of the SMPP v3.4 protocol. It is suitable for writing gateway daemons that communicate with SMSCs for sending and receiving SMS messages.

The implementation is based on the Ruby/EventMachine library.

Glossary
-----------------
SMSC: SMS Center. Mobile operators normally operate an SMSC in their network. The SMSC stores and forwards SMS messages.
MO:   Mobile Originated SMS: originated in a mobile phone, ie. sent by an end user.
MT:   Mobile Terminated SMS: terminated in a mobile phone, ie. received by an end user.
DR:   Delivery Report, or delivery notification. When you send an MT message, you should receive a DR after a while.
PDU:  Protcol Base Unit, the data units that SMPP is comprised of. This implementation does _not_ implement all SMPP PDUs.

Protocol
-----------------
The SMPP 3.4 protocol spec can be downloaded here: http://smsforum.net/SMPP_v3_4_Issue1_2.zip

Testing/Sample Code
-------------------
Logica provides an SMPP simulator that you can download from http://opensmpp.logica.com/. You can 
also sign up for a demo SMPP account at one of the many bulk-SMS providers out there.

For a quick test, download smscsim.jar and smpp.jar from the Logica site, and start the simulator by typing:

java -cp smscsim.jar:smpp.jar com.logica.smscsim.Simulator

Then type 1 (start simulation), and enter 6000 for port number. The simulator then starts a server socket on a background thread. In another terminal window, start the sample sms gateway from the ruby-smpp/examples directory by typing:

./sample_gateway.rb

You will be able to send MT messages from the sample gateway terminal window by typing the message body. In the simulator terminal window you should see SMPP PDUs being sent from the sample gateway. 

You can also send MO messages from the simulator to the sample gateway by typing 7 (log to screen off) and then 4 (send message). MO messages received by the sample gateway will be logged to ./sms_gateway.log.

== FEATURES/PROBLEMS:

* Implements only typical client subset of SMPP 3.4 with single-connection Transceiver as opposed to dual-connection Transmitter + Receiver. 
* Contributors are encouraged to add missing PDUs.
* Need more test cases!

== BASIC USAGE:

Start the transceiver. Receive callbacks whenever incoming messages or delivery reports arrive. Send messages with Transceiver#send_mt. 

<pre>
  # connect to SMSC
  tx = EventMachine::run do             
    $tx = EventMachine::connect(
    host, 
    port, 
    Smpp::Transceiver, 
    config,             # a property hash 
    mo_proc,            # the proc invoked on incoming (MO) messages
    dr_proc,            # the proc invoked on delivery reports
    pdr_storage)        # hash-like storage for pending delivery reports
  end
  
  # send a message
  tx.send_mt(id, from, to, body)
</pre>

For a more complete example, see examples/sample_gateway.rb

== REQUIREMENTS:

* Eventmachine >= 0.10.0

== INSTALL:

* sudo gem install ruby-smpp

== LICENSE:

Copyright (c) 2008 Apparat AS

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
