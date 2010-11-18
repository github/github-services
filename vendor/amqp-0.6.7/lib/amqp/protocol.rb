require File.expand_path('../spec', __FILE__)
require File.expand_path('../buffer', __FILE__)

module AMQP
  module Protocol
    #:stopdoc:
    class Class::Method
      def initialize *args
        opts = args.pop if args.last.is_a? Hash
        opts ||= {}
        
        @debug = 1 # XXX hack, p(obj) == '' if no instance vars are set
        
        if args.size == 1 and args.first.is_a? Buffer
          buf = args.shift
        else
          buf = nil
        end

        self.class.arguments.each do |type, name|
          val = buf ? buf.read(type) :
                      args.shift || opts[name] || opts[name.to_s]
          instance_variable_set("@#{name}", val)
        end
      end

      def arguments
        self.class.arguments.inject({}) do |hash, (type, name)|
          hash.update name => instance_variable_get("@#{name}")
        end
      end

      def to_binary
        buf = Buffer.new
        buf.write :short, self.class.section.id
        buf.write :short, self.class.id

        bits = []

        self.class.arguments.each do |type, name|
          val = instance_variable_get("@#{name}")
          if type == :bit
            bits << (val || false)
          else
            unless bits.empty?
              buf.write :bit, bits
              bits = []
            end
            buf.write type, val
          end
        end

        buf.write :bit, bits unless bits.empty?
        buf.rewind

        buf
      end
      
      def to_s
        to_binary.to_s
      end
      
      def to_frame channel = 0
        Frame::Method.new(self, channel)
      end
    end

    #:startdoc:
    #
    # Contains a properties hash that holds some potentially interesting 
    # information.
    # * :delivery_mode
    # 1 equals transient.
    # 2 equals persistent. Unconsumed persistent messages will survive
    # a server restart when they are stored in a durable queue.
    # * :redelivered
    # True or False
    # * :routing_key
    # The routing string used for matching this message to this queue.
    # * :priority
    # An integer in the range of 0 to 9 inclusive.
    # * :content_type
    # Always "application/octet-stream" (byte stream)
    # * :exchange
    # The source exchange which published this message.
    # * :message_count
    # The number of unconsumed messages contained in the queue.
    # * :delivery_tag
    # A monotonically increasing integer. This number should not be trusted
    # as a sequence number. There is no guarantee it won't get reset.
    class Header
      def initialize *args
        opts = args.pop if args.last.is_a? Hash
        opts ||= {}
        
        first = args.shift
        
        if first.is_a? ::Class and first.ancestors.include? Protocol::Class
          @klass = first
          @size = args.shift || 0
          @weight = args.shift || 0
          @properties = opts

        elsif first.is_a? Buffer or first.is_a? String
          buf = first
          buf = Buffer.new(buf) unless buf.is_a? Buffer
          
          @klass = Protocol.classes[buf.read(:short)]
          @weight = buf.read(:short)
          @size = buf.read(:longlong)

          props = buf.read(:properties, *klass.properties.map{|type,_| type })
          @properties = Hash[*klass.properties.map{|_,name| name }.zip(props).reject{|k,v| v.nil? }.flatten]

        else
          raise ArgumentError, 'Invalid argument'
        end
        
      end
      attr_accessor :klass, :size, :weight, :properties
      
      def to_binary
        buf = Buffer.new
        buf.write :short, klass.id
        buf.write :short, weight # XXX rabbitmq only supports weight == 0
        buf.write :longlong, size
        buf.write :properties, (klass.properties.map do |type, name|
                                 [ type, properties[name] || properties[name.to_s] ]
                               end)
        buf.rewind
        buf
      end
      
      def to_s
        to_binary.to_s
      end

      def to_frame channel = 0
        Frame::Header.new(self, channel)
      end

      def == header
        [ :klass, :size, :weight, :properties ].inject(true) do |eql, field|
          eql and __send__(field) == header.__send__(field)
        end
      end

      def method_missing meth, *args, &blk
        @properties.has_key?(meth) || @klass.properties.find{|_,name| name == meth } ? @properties[meth] :
                                                                                       super
      end
    end

    def self.parse buf
      buf = Buffer.new(buf) unless buf.is_a? Buffer
      class_id, method_id = buf.read(:short, :short)
      classes[class_id].methods[method_id].new(buf)
    end
    #:stopdoc:
  end
end

if $0 =~ /bacon/ or $0 == __FILE__
  require 'bacon'
  include AMQP

  describe Protocol do
    should 'instantiate methods with arguments' do
      meth = Protocol::Connection::StartOk.new nil, 'PLAIN', nil, 'en_US'
      meth.locale.should == 'en_US'
    end

    should 'instantiate methods with named parameters' do
      meth = Protocol::Connection::StartOk.new :locale => 'en_US',
                                               :mechanism => 'PLAIN'
      meth.locale.should == 'en_US'
    end

    should 'convert methods to binary' do
      meth = Protocol::Connection::Secure.new :challenge => 'secret'
      meth.to_binary.should.be.kind_of? Buffer

      meth.to_s.should == [ 10, 20, 6, 'secret' ].pack('nnNa*')
    end

    should 'convert binary to method' do
      orig = Protocol::Connection::Secure.new :challenge => 'secret'
      copy = Protocol.parse orig.to_binary
      orig.should == copy
    end

    should 'convert headers to binary' do
      head = Protocol::Header.new Protocol::Basic,
                                  size = 5,
                                  weight = 0,
                                  :content_type => 'text/json',
                                  :delivery_mode => 1,
                                  :priority => 1
      head.to_s.should == [ 60, weight, 0, size, 0b1001_1000_0000_0000, 9, 'text/json', 1, 1 ].pack('nnNNnCa*CC')
    end

    should 'convert binary to header' do
      orig = Protocol::Header.new Protocol::Basic,
                                  size = 5,
                                  weight = 0,
                                  :content_type => 'text/json',
                                  :delivery_mode => 1,
                                  :priority => 1
      Protocol::Header.new(orig.to_binary).should == orig
    end
  end
end
