#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r'
# No include Jabber, test full namespace

class JIDTest < Test::Unit::TestCase
  def test_base
    assert_kind_of(Module, Jabber)
    assert_kind_of(Class, Jabber::AuthenticationFailure)
    assert_kind_of(Class, Jabber::Client)
    assert_kind_of(Class, Jabber::Component)
    assert_kind_of(Class, Jabber::Connection)
    assert_kind_of(Class, Jabber::Error)
    assert_kind_of(Class, Jabber::ErrorException)
    assert_kind_of(Class, Jabber::IdGenerator)
    assert_kind_of(Class, Jabber::Iq)
    assert_kind_of(Class, Jabber::IqQuery)
    assert_kind_of(Class, Jabber::JID)
    assert_kind_of(Class, Jabber::Message)
    assert_kind_of(Class, Jabber::Presence)
    assert_kind_of(Module, Jabber::SASL)
    assert_respond_to(Jabber::SASL, :new)
    assert_kind_of(Class, Jabber::SASL::Base)
    assert_kind_of(Class, Jabber::SASL::Plain)
    assert_kind_of(Class, Jabber::SASL::DigestMD5)
    assert_kind_of(Class, Jabber::Stream)
    assert_kind_of(Class, Jabber::StreamParser)
    assert_kind_of(Class, Jabber::X)
    assert_kind_of(Class, Jabber::XMPPElement)
    assert_kind_of(Class, Jabber::XMPPStanza)
  end

  def test_roster
    require 'xmpp4r/roster'
    assert_kind_of(Module, Jabber::Roster)
    assert_kind_of(Class, Jabber::Roster::Helper)
    assert_kind_of(Class, Jabber::Roster::Helper::RosterItem)
    assert_kind_of(Class, Jabber::Roster::RosterItem)
    assert_kind_of(Class, Jabber::Roster::IqQueryRoster)
    assert_kind_of(Class, Jabber::Roster::XRoster)
    assert_kind_of(Class, Jabber::Roster::XRosterItem)
  end

  def test_muc
    require 'xmpp4r/muc'
    assert_kind_of(Module, Jabber::MUC)
    assert_kind_of(Class, Jabber::MUC::MUCBrowser)
    assert_kind_of(Class, Jabber::MUC::MUCClient)
    assert_kind_of(Class, Jabber::MUC::SimpleMUCClient)
    assert_kind_of(Class, Jabber::MUC::XMUC)
    assert_kind_of(Class, Jabber::MUC::XMUCUser)
    assert_kind_of(Class, Jabber::MUC::XMUCUserInvite)
  end

  def test_bytestreams
    require 'xmpp4r/bytestreams'
    assert_kind_of(Module, Jabber::FileTransfer)
    assert_kind_of(Module, Jabber::FileTransfer::TransferSource)
    assert_kind_of(Class, Jabber::FileTransfer::FileSource)
    assert_kind_of(Class, Jabber::FileTransfer::Helper)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5BytestreamsServer)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5BytestreamsServerStreamHost)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5BytestreamsPeer)
    assert_kind_of(Class, Jabber::Bytestreams::IqQueryBytestreams)
    assert_kind_of(Class, Jabber::Bytestreams::StreamHost)
    assert_kind_of(Class, Jabber::Bytestreams::StreamHostUsed)
    assert_kind_of(Class, Jabber::Bytestreams::IqSi)
    assert_kind_of(Class, Jabber::Bytestreams::IqSiFile)
    assert_kind_of(Class, Jabber::Bytestreams::IqSiFileRange)
    assert_kind_of(Class, Jabber::Bytestreams::IBB)
    assert_kind_of(Class, Jabber::Bytestreams::IBBQueueItem)
    assert_kind_of(Class, Jabber::Bytestreams::IBBInitiator)
    assert_kind_of(Class, Jabber::Bytestreams::IBBTarget)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5Bytestreams)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5BytestreamsInitiator)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5BytestreamsTarget)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5Error)
    assert_kind_of(Class, Jabber::Bytestreams::SOCKS5Socket)
  end
  
  def test_dataforms
    require 'xmpp4r/dataforms'
    assert_kind_of(Module, Jabber::Dataforms)
    assert_kind_of(Class, Jabber::Dataforms::XData)
    assert_kind_of(Class, Jabber::Dataforms::XDataTitle)
    assert_kind_of(Class, Jabber::Dataforms::XDataInstructions)
    assert_kind_of(Class, Jabber::Dataforms::XDataField)
    assert_kind_of(Class, Jabber::Dataforms::XDataReported)
  end
  
  def test_delay
    require 'xmpp4r/delay'
    assert_kind_of(Module, Jabber::Delay)
    assert_kind_of(Class, Jabber::Delay::XDelay)
  end

  def test_discovery
    require 'xmpp4r/discovery'
    assert_kind_of(Module, Jabber::Discovery)
    assert_kind_of(Class, Jabber::Discovery::IqQueryDiscoInfo)
    assert_kind_of(Class, Jabber::Discovery::Identity)
    assert_kind_of(Class, Jabber::Discovery::Feature)
    assert_kind_of(Class, Jabber::Discovery::IqQueryDiscoItems)
    assert_kind_of(Class, Jabber::Discovery::Item)
  end

  def test_feature_negotiation
    require 'xmpp4r/feature_negotiation'
    assert_kind_of(Module, Jabber::FeatureNegotiation)
    assert_kind_of(Class, Jabber::FeatureNegotiation::IqFeature)
  end

  def test_vcard
    require 'xmpp4r/vcard'
    assert_kind_of(Module, Jabber::Vcard)
    assert_kind_of(Class, Jabber::Vcard::Helper)
    assert_kind_of(Class, Jabber::Vcard::IqVcard)
  end

  def test_version
    require 'xmpp4r/version'
    assert_kind_of(Module, Jabber::Version)
    assert_kind_of(Class, Jabber::Version::Responder)
    assert_kind_of(Class, Jabber::Version::SimpleResponder)
    assert_kind_of(Class, Jabber::Version::IqQueryVersion)
  end

  def test_rpc
    require 'xmpp4r/rpc'
    assert_kind_of(Module, Jabber::RPC)
    assert_kind_of(Class, Jabber::RPC::Server)
    assert_kind_of(Class, Jabber::RPC::Client)
  end
end
