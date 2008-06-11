#!/usr/bin/ruby

$:.unshift '../lib'

require 'xmpp4r'
include Jabber

c = Component::new('example.blop.info', 'linux.ensimag.fr', 2609)
c.connect
c.auth('BenEuh')
c.add_iq_callback { |i|
puts i.to_s
}

c.add_message_callback { |m|
  puts m.to_s
}
Thread.stop
