require 'enumerator'

require 'rubygems'
require 'eventmachine'

require 'amqp_spec'

module AMQP
  class BufferOverflow < StandardError; end
  class InvalidFrame < StandardError; end

  module Protocol
    class Class::Method
      def initialize *args
        opts = args.pop if args.size == 1 and args.last.is_a? Hash
        opts ||= {}
        
        # XXX hack, p(obj) == '' if no instance vars are set
        @debug = 1
        
        if args.size == 1 and args.first.is_a? Buffer
          buf = args.first
        else
          buf = nil
        end

        self.class.arguments.each do |type, name|
          if buf
            val = buf.parse(type)
          else
            val = args.shift || opts[name] || opts[name.to_s]
          end

          instance_variable_set("@#{name}", val)
        end
      end

      def convert_bits
        if @bits.size > 0
          data = @bits.to_enum(:each_slice, 8).inject(''){|octet, list|
           octet + pack(:octet,
             list.enum_with_index.inject(0){ |byte, (bit, i)|
              byte |= 1<<i if bit
              byte
             }
           )
          }
          @bits = []
        end
        
        data || ''
      end

      def to_binary
        @bits = []

        pack(:short, self.class.parent.id) +
        pack(:short, self.class.id) +
        self.class.arguments.inject(''){ |data, (type, name)|
          if type == :bit
            @bits << (instance_variable_get("@#{name}") || false)
            data
          else
            data + convert_bits + pack(type, instance_variable_get("@#{name}"))
          end
        } + convert_bits
      end
      alias :to_s :to_binary
      
      def to_frame channel = 0
        Frame.new(:METHOD, channel, self)
      end
      
      private
      
      def pack type, data
        # p ['pack', type, data]

        case type
          when :octet
            [data].pack('C')
          when :short
            [data].pack('n')
          when :long
            [data].pack('N')
          when :shortstr
            data ||= ''
            len = data.length
            [len, data].pack("Ca#{len}")
          when :longstr
            if data.is_a? Hash
              pack(:table, data)
            else
              len = data.length
              [len, data].pack("Na#{len}")
            end
          when :table
            data ||= {}
            pack :longstr, (data.inject('') do |str, (key, value)|
                             str +
                             pack(:shortstr, key.to_s) +
                             pack(:octet, ?S) +
                             pack(:longstr, value.to_s) # XXX support other field types here
                           end)
          when :longlong
            lower = l & 0xffffffff
            upper = (l & ~0xffffffff) >> 32
            pack(:long, upper) + pack(:long, lower)
          when :bit
            data = if data.nil? or data == false or data == 0
                     0
                   else
                     1
                   end
            pack(:octet, data)
        end
      end
    end

    def self.parse payload
      buf = Buffer.new(payload)
      class_id, method_id = buf.parse(:short, :short)
      classes[class_id].methods[method_id].new(buf)
    end
  end

  class Frame
    def initialize type, channel, payload
      @channel = channel
      @type = (1..8).include?(type) ? TYPES[type] :
                                      TYPES.include?(type) ? type : raise(InvalidFrame)

      if @type == :METHOD and payload.is_a? String
        @payload = Protocol.parse(payload)
      else
        @payload = payload
      end
    end
    attr_reader :type, :channel, :payload

    def to_binary
      data = payload.to_s
      size = data.length
      # XXX the spec falsely claims there is another empty 'cycle' octet in this header
      [TYPES.index(type), channel, size, data, FOOTER].pack("CnNa*C")
    end
    alias :to_s :to_binary

    def == b
      [ :type, :channel, :payload ].inject(true){|eql, field| eql and __send__(field) == b.__send__(field) }
    end

    def self.extract data
      (@buffer ||= Buffer.new).extract(data.to_s)
    end
  end

  class Buffer
    def initialize data = ''
      @data = data
      @pos = 0
    end
    attr_reader :pos
    
    def extract data = nil
      @data << data if data
      
      processed = 0
      frames = []

      while true
        type, channel, size = parse(:octet, :short, :long)
        payload = read(size)
        if read(1) == Frame::FOOTER.chr
          frames << Frame.new(type, channel, payload)
        else
          raise InvalidFrame
        end
        processed = @pos
      end
    rescue BufferOverflow
      # log 'buffer overflow', @pos, processed
      @data[0..processed] = '' if processed > 0
      @pos = 0
      frames
    end

    def parse *syms
      res = syms.map do |sym|
        # log 'parsing', sym
        case sym
          when :octet
            read(1, 'C')
          when :short
            read(2, 'n')
          when :long
            read(4, 'N')
          when :longlong
            # FIXME
          when :shortstr
            len = parse(:octet)
            read(len)
          when :longstr
            len = parse(:long)
            read(len)
          when :timestamp
            parse(:longlong)
          when :bit
            # FIXME
          when :table
            t = Hash.new

            table = Buffer.new(parse(:longstr))
            until table.eof?
              key, type = table.parse(:shortstr, :octet)
              t[key] = case type
                         when ?S
                           table.parse(:longstr)
                         when ?I
                           table.parse(:long)
                         when ?D
                           d = table.parse(:octet)
                           table.parse(:long) / (10**d)
                         when ?T
                           table.parse(:timestamp)
                         when ?F
                           table.parse(:table)
                       end
            end

            t
          else
            # FIXME remove
        end
      end

      syms.length == 1 ? res[0] : res
    end

    def read len, type = nil
      # log 'reading', len, type, :pos => @pos
      raise BufferOverflow if @pos+len > @data.length

      d = @data.slice(@pos, len)
      @pos += len
      d = d.unpack(type).pop if type
      # log 'read', d
      d
    end

    def eof?
      @pos == @data.length
    end

    private

    def log *args
      p args
    end
  end

  module Connection
    def initialize blk
      @blk = blk
    end

    def connection_completed
      log 'connected'
      send_data HEADER
      send_data [1, 1, VERSION_MAJOR, VERSION_MINOR].pack('CCCC')
    end
  
    def receive_data data
      # log 'receive_data', data

      Frame.extract(data).each do |frame|
        log 'receive', frame
        
        case method = frame.payload
        when Protocol::Connection::Start
          send Protocol::Connection::StartOk.new({:platform => 'Ruby/EventMachine',
                                                  :product => 'AMQP',
                                                  :information => 'http://github.com/tmm1/amqp',
                                                  :version => '0.0.1'},
                                                 'AMQPLAIN',
                                                 {:LOGIN => 'guest',
                                                  :PASSWORD => 'guest'},
                                                 'en_US')

        when Protocol::Connection::Tune
          send Protocol::Connection::TuneOk.new :channel_max => 0,
                                                :frame_max => 131072,
                                                :heartbeat => 0

          send Protocol::Connection::Open.new :virtual_host => '/',
                                              :capabilities => '',
                                              :insist => false

        when Protocol::Connection::OpenOk
          send Protocol::Channel::Open.new, :channel => 1
        
        when Protocol::Channel::OpenOk
          send Protocol::Access::Request.new(:realm => '/data',
                                             :read => true,
                                             :write => true,
                                             :active => true), :channel => 1

        when Protocol::Access::RequestOk
          @ticket = method.ticket
          send Protocol::Queue::Declare.new(:ticket => @ticket,
                                            :queue => '',
                                            :exclusive => false,
                                            :auto_delete => true), :channel => 1

        when Protocol::Queue::DeclareOk
          @queue = method.queue
          send Protocol::Queue::Bind.new(:ticket => @ticket,
                                         :queue => @queue,
                                         :exchange => '',
                                         :routing_key => 'test_route'), :channel => 1

        when Protocol::Queue::BindOk
          send Protocol::Basic::Consume.new(:ticket => @ticket,
                                            :queue => @queue,
                                            :no_local => false,
                                            :no_ack => true), :channel => 1

        when Protocol::Basic::ConsumeOk
          send Protocol::Basic::Publish.new(:ticket => @ticket,
                                            :exchange => '',
                                            :routing_key => 'test_route'), :channel => 1, :content => 'this is a test!'
        end
      end
    end
  
    def send data, opts = {}
      channel = opts[:channel] ||= 0
      data = data.to_frame(channel) unless data.is_a? Frame
      log 'send', data
      send_data data.to_binary

      if content = opts[:content]
        size = content.length

        lower = size & 0xffffffff
        upper = (size & ~0xffffffff) >> 32
        # XXX rabbitmq only supports weight == 0
        data = [ 60, weight = 0, upper, lower, 0b1001_1000_0000_0000 ].pack("nnNNn")
        data += [ len = 'application/octet-stream'.length, 'application/octet-stream', 1, 1 ].pack("Ca*CC")
        send_data Frame.new(:HEADER, channel, data).to_binary

        # XXX spec says add FRAME_END, but rabbitmq doesn't support it
        # data = [ content, Frame::FOOTER ].pack('a*C')
        data = [ content ].pack("a*")
        send_data Frame.new(:BODY, channel, data).to_binary
      end
    end

    def send_data data
      log 'send_data', data
      super
    end

    def unbind
      log 'disconnected'
    end
  
    def self.start host = 'localhost', port = PORT, &blk
      EM.run{
        EM.connect host, port, self, blk
      }
    end
  
    private
  
    def log *args
      pp args
      puts
    end
  end

  def self.start *args, &blk
    Connection.start *args, &blk
  end
end

require 'pp'

if $0 == __FILE__
  EM.run{
    AMQP.start do |amqp|
      amqp.test.integer { |meth|
        meth
      }.send(0)
      
      amqp(1).on(:method) {
        
      }
      
      amqp(1).test.integer
    end
  }
elsif $0 =~ /bacon/
  include AMQP

  describe Frame do
    should 'convert to binary' do
      Frame.new(2, 0, 'abc').to_binary.should == "\002\000\000\000\000\000\003abc\316"
    end

    should 'return type as symbol' do
      Frame.new(3, 0, 'abc').type.should == :BODY
      Frame.new(:BODY, 0, 'abc').type.should == :BODY
    end

    should 'wrap Buffer#extract' do
      Frame.extract(frame = Frame.new(2,0,'abc')).first.should == frame
    end
  end
  
  describe Buffer do
    @frame = Frame.new(2, 0, 'abc')
    
    should 'parse complete frames' do
      frame = Buffer.new(@frame.to_binary).extract.first

      frame.should.be.kind_of? Frame
      frame.should.be == @frame
    end

    should 'not return incomplete frames until complete' do
      buffer = Buffer.new(@frame.to_binary[0..5])
      buffer.extract.should == []
      buffer.extract(@frame.to_binary[6..-1]).should == [@frame]
      buffer.extract.should == []
    end
  end

  describe Protocol do
    @start = Protocol::Connection::Start.new(:locales => 'en_US',
                                             :mechanisms => 'PLAIN AMQPLAIN',
                                             :version_major => 8,
                                             :version_minor => 0,
                                             :server_properties => {'product' => 'RabbitMQ'})
  
    @startok = Protocol::Connection::StartOk.new({:platform => 'Ruby/EventMachine',
                                                  :product => 'AMQP',
                                                  :information => 'http://github.com/tmm1/amqp',
                                                  :version => '0.0.1'},
                                                 'PLAIN',
                                                 {:LOGIN => 'guest',
                                                  :PASSWORD => 'guest'},
                                                 'en_US')
                                                      
    should 'generate method packets' do
      meth = Protocol::Connection::StartOk.new :locale => 'en_US',
                                               :mechanism => 'PLAIN'
      meth.locale.should == @startok.locale
    end

    should 'generate method frames' do
      @startok.to_frame.should == Frame.new(:METHOD, 0, @startok)
    end
    
    should 'convert to and from binary' do
      Protocol.parse(@start.to_binary).should == @start
    end

    should 'convert to and from frames' do
      # XXX make this Frame.parse (refactor Buffer#extract)
      Buffer.new(@start.to_frame.to_binary).extract.first.payload.should == @start
    end
  end
end

__END__

["connected"]

["receive",
 #<AMQP::Frame:0x1063834
  @channel=0,
  @payload=
   #<AMQP::Protocol::Connection::Start:0x1063500
    @debug=1,
    @locales="en_US",
    @mechanisms="PLAIN AMQPLAIN",
    @server_properties=
     {"platform"=>"Erlang/OTP",
      "product"=>"RabbitMQ",
      "information"=>"Licensed under the MPL.  See http://www.rabbitmq.com/",
      "version"=>"%%VERSION%%",
      "copyright"=>
       "Copyright (C) 2007-2008 LShift Ltd., Cohesive Financial Technologies LLC., and Rabbit Technologies Ltd."},
    @version_major=8,
    @version_minor=0>,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x104c5bc
  @channel=0,
  @payload=
   #<AMQP::Protocol::Connection::StartOk:0x104c7d8
    @client_properties=
     {:product=>"AMQP",
      :information=>"http://github.com/tmm1/amqp",
      :platform=>"Ruby/EventMachine",
      :version=>"0.0.1"},
    @debug=1,
    @locale="en_US",
    @mechanism="AMQPLAIN",
    @response={:PASSWORD=>"guest", :LOGIN=>"guest"}>,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x1035b78
  @channel=0,
  @payload=
   #<AMQP::Protocol::Connection::Tune:0x1035844
    @channel_max=0,
    @debug=1,
    @frame_max=131072,
    @heartbeat=0>,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x102ad18
  @channel=0,
  @payload=
   #<AMQP::Protocol::Connection::TuneOk:0x102af34
    @channel_max=0,
    @debug=1,
    @frame_max=131072,
    @heartbeat=0>,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x1020034
  @channel=0,
  @payload=
   #<AMQP::Protocol::Connection::Open:0x1020278
    @capabilities="",
    @debug=1,
    @insist=nil,
    @virtual_host="/">,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x1014e8c
  @channel=0,
  @payload=
   #<AMQP::Protocol::Connection::OpenOk:0x1014b58
    @debug=1,
    @known_hosts="julie.local:5672">,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x100c138
  @channel=1,
  @payload=
   #<AMQP::Protocol::Channel::Open:0x100c37c @debug=1, @out_of_band=nil>,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x10036a0
  @channel=1,
  @payload=#<AMQP::Protocol::Channel::OpenOk:0x100336c @debug=1>,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x60e7e4
  @channel=1,
  @payload=
   #<AMQP::Protocol::Access::Request:0x60ef14
    @active=true,
    @debug=1,
    @exclusive=nil,
    @passive=nil,
    @read=true,
    @realm="/data",
    @write=true>,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x5dd4b4
  @channel=1,
  @payload=#<AMQP::Protocol::Access::RequestOk:0x5dcc30 @debug=1, @ticket=101>,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x5c02d8
  @channel=1,
  @payload=
   #<AMQP::Protocol::Queue::Declare:0x5c08dc
    @arguments=nil,
    @auto_delete=true,
    @debug=1,
    @durable=nil,
    @exclusive=nil,
    @nowait=nil,
    @passive=nil,
    @queue="",
    @ticket=101>,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x58d1bc
  @channel=1,
  @payload=
   #<AMQP::Protocol::Queue::DeclareOk:0x58cbb8
    @consumer_count=0,
    @debug=1,
    @message_count=0,
    @queue="amq.gen-FiDSuLv/KvSgdcIWrNOdYg==">,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x570f44
  @channel=1,
  @payload=
   #<AMQP::Protocol::Queue::Bind:0x571624
    @arguments=nil,
    @debug=1,
    @exchange="",
    @nowait=nil,
    @queue="amq.gen-FiDSuLv/KvSgdcIWrNOdYg==",
    @routing_key="test_route",
    @ticket=101>,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x549124
  @channel=1,
  @payload=#<AMQP::Protocol::Queue::BindOk:0x54897c @debug=1>,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x5339f0
  @channel=1,
  @payload=
   #<AMQP::Protocol::Basic::Consume:0x534120
    @consumer_tag=nil,
    @debug=1,
    @exclusive=nil,
    @no_ack=true,
    @no_local=nil,
    @nowait=nil,
    @queue="amq.gen-FiDSuLv/KvSgdcIWrNOdYg==",
    @ticket=101>,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x503d04
  @channel=1,
  @payload=
   #<AMQP::Protocol::Basic::ConsumeOk:0x5035d4
    @consumer_tag="amq.ctag-r6XkTE2+kN1qqbMG7FXraQ==",
    @debug=1>,
  @type=:METHOD>]

["send",
 #<AMQP::Frame:0x365498
  @channel=1,
  @payload=
   #<AMQP::Protocol::Basic::Publish:0x366cbc
    @debug=1,
    @exchange="",
    @immediate=nil,
    @mandatory=nil,
    @routing_key="test_route",
    @ticket=101>,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x11fd000
  @channel=1,
  @payload=
   #<AMQP::Protocol::Basic::Deliver:0x11fc4fc
    @consumer_tag="amq.ctag-r6XkTE2+kN1qqbMG7FXraQ==",
    @debug=1,
    @delivery_tag=nil,
    @exchange="",
    @redelivered=nil,
    @routing_key="">,
  @type=:METHOD>]

["receive",
 #<AMQP::Frame:0x11fb534
  @channel=1,
  @payload=
   "\000<\000\000\000\000\000\000\000\000\000\017\230\000\030application/octet-stream\001\001",
  @type=:HEADER>]

["receive",
 #<AMQP::Frame:0x11faef4 @channel=1, @payload="this is a test!", @type=:BODY>]