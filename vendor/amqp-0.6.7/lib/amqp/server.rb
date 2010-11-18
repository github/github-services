require File.expand_path('../frame', __FILE__)

module AMQP
  module Server
    def post_init
      @buf = ''
      @channels = {}
      @started = false
    end

    def receive_data data
      @buf << data

      unless @started
        if @buf.size >= 8
          if @buf.slice!(0,8) == "AMQP\001\001\b\000"
            send Protocol::Connection::Start.new(
              8,
              0,
              {
                :information => 'Licensed under the Ruby license. See http://github.com/tmm1/amqp',
                :copyright => 'Copyright (c) 2008-2009 Aman Gupta',
                :platform => 'Ruby/EventMachine',
                :version => '0.6.1',
                :product => 'SquirrelMQ'
              },
              'PLAIN AMQPLAIN',
              'en_US'
            )
          else
            close_connection
            return
          end
          @started = true
        else
          return
        end
      end

      while frame = Frame.parse(@buf)
        process_frame frame
      end
    end

    def process_frame frame
      channel = frame.channel

      case method = frame.payload
      when Protocol::Connection::StartOk
        @user = method.response[:LOGIN]
        @pass = method.response[:PASSWORD]
        send Protocol::Connection::Tune.new(0, 131072, 0)

      when Protocol::Connection::TuneOk
        # mnnk

      when Protocol::Connection::Open
        @vhost = method.virtual_host
        send Protocol::Connection::OpenOk.new('localhost')

      when Protocol::Channel::Open
        @channels[channel] = []
        send Protocol::Channel::OpenOk.new, :channel => channel

      when Protocol::Access::Request
        send Protocol::Access::RequestOk.new(101)
      end
    end

    def send data, opts = {}
      channel = opts[:channel] ||= 0
      data = data.to_frame(channel) unless data.is_a? Frame
      data.channel = channel

      log 'send', data
      send_data data.to_s
    end

    def self.start host = 'localhost', port = 5672
      EM.start_server host, port, self
    end

    private
  
    def log *args
      require 'pp'
      pp args
      puts
    end
  end
end

if __FILE__ == $0
  require 'rubygems'
  require 'eventmachine'
  EM.run{
    AMQP::Server.start
  }
end
