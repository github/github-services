require File.expand_path('../spec', __FILE__)
require File.expand_path('../buffer', __FILE__)
require File.expand_path('../protocol', __FILE__)

module AMQP
  class Frame #:nodoc: all
    def initialize payload = nil, channel = 0
      @channel, @payload = channel, payload
    end
    attr_accessor :channel, :payload

    def id
      self.class::ID
    end
    
    def to_binary
      buf = Buffer.new
      buf.write :octet, id
      buf.write :short, channel
      buf.write :longstr, payload
      buf.write :octet, FOOTER
      buf.rewind
      buf
    end

    def to_s
      to_binary.to_s
    end

    def == frame
      [ :id, :channel, :payload ].inject(true) do |eql, field|
        eql and __send__(field) == frame.__send__(field)
      end
    end
    
    class Invalid < StandardError; end
    
    class Method
      def initialize payload = nil, channel = 0
        super
        unless @payload.is_a? Protocol::Class::Method or @payload.nil?
          @payload = Protocol.parse(@payload)
        end
      end
    end

    class Header
      def initialize payload = nil, channel = 0
        super
        unless @payload.is_a? Protocol::Header or @payload.nil?
          @payload = Protocol::Header.new(@payload)
        end
      end
    end

    class Body; end

    def self.parse buf
      buf = Buffer.new(buf) unless buf.is_a? Buffer
      buf.extract do
        id, channel, payload, footer = buf.read(:octet, :short, :longstr, :octet)
        Frame.types[id].new(payload, channel) if footer == FOOTER
      end
    end
  end
end

if $0 =~ /bacon/ or $0 == __FILE__
  require 'bacon'
  include AMQP

  describe Frame do
    should 'handle basic frame types' do
      Frame::Method.new.id.should == 1
      Frame::Header.new.id.should == 2
      Frame::Body.new.id.should == 3
    end

    should 'convert method frames to binary' do
      meth = Protocol::Connection::Secure.new :challenge => 'secret'

      frame = Frame::Method.new(meth)
      frame.to_binary.should.be.kind_of? Buffer
      frame.to_s.should == [ 1, 0, meth.to_s.length, meth.to_s, 206 ].pack('CnNa*C')
    end

    should 'convert binary to method frames' do
      orig = Frame::Method.new Protocol::Connection::Secure.new(:challenge => 'secret')

      copy = Frame.parse(orig.to_binary)
      copy.should == orig
    end

    should 'ignore partial frames until ready' do
      frame = Frame::Method.new Protocol::Connection::Secure.new(:challenge => 'secret')
      data = frame.to_s

      buf = Buffer.new
      Frame.parse(buf).should == nil
      
      buf << data[0..5]
      Frame.parse(buf).should == nil
      
      buf << data[6..-1]
      Frame.parse(buf).should == frame
      
      Frame.parse(buf).should == nil
    end

    should 'convert header frames to binary' do
      head = Protocol::Header.new(Protocol::Basic, :priority => 1)
      
      frame = Frame::Header.new(head)
      frame.to_s.should == [ 2, 0, head.to_s.length, head.to_s, 206 ].pack('CnNa*C')
    end

    should 'convert binary to header frame' do
      orig = Frame::Header.new Protocol::Header.new(Protocol::Basic, :priority => 1)
      
      copy = Frame.parse(orig.to_binary)
      copy.should == orig
    end
  end
end
