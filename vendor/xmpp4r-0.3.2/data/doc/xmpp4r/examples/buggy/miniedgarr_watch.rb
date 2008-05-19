#!/usr/bin/ruby

$:.unshift '../lib'

require 'rexml/document'

require 'xmpp4r'
require 'xmpp4r/iqqueryroster'

# Command line argument checking

if ARGV.size != 3
  puts("Usage: ./rosterwatch.rb <jid> <password> <statefile>")
  exit
end


def write_state(statefile, roster, presences)
  doc = REXML::Document.new
  state = doc.add(REXML::Element.new('state'))
  state.add(roster)
  presences.each { |jid,pres| state.add(pres) }

  file = File.new(statefile, "w")
  doc.write(file, 0)
  file.close
end


# Building up the connection

Jabber::debug = true

jid = Jabber::JID.new(ARGV[0])

cl = Jabber::Client.new(jid, false)
cl.connect
cl.auth(ARGV[1])


roster = Jabber::IqQueryRoster.new
presences = {}

cl.add_iq_callback { |iq|
  if (iq.type == :result) && iq.query.kind_of?(Jabber::IqQueryRoster)
    roster.import(iq.query)
    write_state(ARGV[2], roster, presences)
  end
}

# TODO: <presence><x xmlns='jabber:x:delay'>...</x></presence>
cl.add_presence_callback { |pres|
  # Handle subscription request
  if pres.type == :subscribe
    # Accept subscription
    cl.send(Jabber::Presence.new.set_to(pres.from).set_type(:subscribed))
    # Subscribe to sender
    cl.send(Jabber::Presence.new.set_to(pres.from).set_type(:subscribe))
    # Add to roster
    # TODO: Resolve Nickname from vCard
    roster_set_iq = Jabber::Iq.new(:set)
    roster_set_iq.add(Jabber::IqQueryRoster.new).add(Jabber::RosterItem.new(pres.from.strip))
    cl.send(roster_set_iq)
  end
  
  presences[pres.from] = pres
  write_state(ARGV[2], roster, presences)
}

# Send request for roster
cl.send(Jabber::Iq.new_rosterget)
# Send initial presence
# This is important as it ensures reception of
# further <presence/> stanzas
cl.send(Jabber::Presence.new.set_show(:dnd).set_status('Watching my roster change...'))

loop do
  cl.process
  sleep(1)
end

cl.close
