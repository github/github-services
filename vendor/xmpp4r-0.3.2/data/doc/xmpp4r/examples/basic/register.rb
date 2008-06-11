#!/usr/bin/ruby

$:.unshift '../../../../../lib'
require 'xmpp4r'


# Argument checking
if ARGV.size != 2
  puts("Usage: #{$0} <desired jid> <password>")
  exit
end


# The usual procedure
cl = Jabber::Client.new(Jabber::JID.new(ARGV[0]))
puts "Connecting"
cl.connect

# Registration of the new user account
puts "Registering..."
cl.register(ARGV[1])
puts "Successful"

# Shutdown
cl.close
