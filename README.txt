Ruby-SMPP is a Ruby implementation of the SMPP v3.4 protocol. It is suitable for writing gateway daemons that communicate with SMSCs for sending and receiving SMS messages.

The implementation is based on the Ruby/EventMachine library.

Glossary
-----------------
SMSC: SMS Center. Mobile operators normally operate an SMSC in their network. The SMSC stores and forwards SMS messages.
MO:   Mobile Originated SMS: originated in a mobile phone, ie. send by an end user.
MT:   Mobile Terminated SMS: terminated in a mobile phone, ie. received by an end user.
DR:   Delivery Report, or delivery notification. When you send an MT message, you should receive a DR after a while.
PDU:  Protcol Base Unit, the data units that SMPP is comprised of. This implementation does _not_ implement all SMPP PDUs.

Protocol
-----------------
The SMPP 3.4 protocol spec can be downloaded here: http://smsforum.net/SMPP_v3_4_Issue1_2.zip

Testing
-----------------
Logica provides an SMPP simulator that you can download from http://opensmpp.logica.com/. You can 
also sign up for a demo SMPP account at one of the many bulk-SMS providers out there.

So it goes.

August Z. Flatby
Apparat AS