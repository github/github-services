#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r'
require 'xmpp4r/muc'
include Jabber

class MUCOwnerTest < Test::Unit::TestCase
  def test_parse
    s = <<EOF
<iq from='darkcave@macbeth.shakespeare.lit'
    id='config1'
    to='crone1@shakespeare.lit/desktop'
    type='result'>
  <query xmlns='http://jabber.org/protocol/muc#owner'>
    <x xmlns='jabber:x:data' type='form'>
      <title>Configuration for "darkcave" Room</title>
      <instructions>
        Complete this form to make changes to
        the configuration of your room.
      </instructions>
      <field
          type='hidden'
          var='FORM_TYPE'>
        <value>http://jabber.org/protocol/muc#roomconfig</value>
      </field>
      <field
          label='Natural-Language Room Name'
          type='text-single'
          var='muc#roomconfig_roomname'>
        <value>A Dark Cave</value>
      </field>
    </x>
  </query>
</iq>
EOF
    iq = Iq::import(REXML::Document.new(s).root)

    assert_kind_of(Iq, iq)
    assert_kind_of(MUC::IqQueryMUCOwner, iq.query)
    assert_kind_of(Dataforms::XData, iq.query.x)
    assert_kind_of(Dataforms::XData, iq.query.x('jabber:x:data'))
    assert_kind_of(Dataforms::XData, iq.query.x(Dataforms::XData))

    assert_equal(1, iq.query.x.fields.size)
    assert_equal('Natural-Language Room Name', iq.query.x.fields[0].label)
  end
end
