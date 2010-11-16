$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'amqp'

module SimpleClient
  def process_frame frame
    case frame
    when Frame::Body
      EM.stop_event_loop

    when Frame::Method
      case method = frame.payload
      when Protocol::Connection::Start
        send Protocol::Connection::StartOk.new({:platform => 'Ruby/EventMachine',
                                                :product => 'AMQP',
                                                :information => 'http://github.com/tmm1/amqp',
                                                :version => '0.1.0'},
                                               'AMQPLAIN',
                                               {:LOGIN => 'guest',
                                                :PASSWORD => 'guest'},
                                               'en_US')

      when Protocol::Connection::Tune
        send Protocol::Connection::TuneOk.new(:channel_max => 0,
                                              :frame_max => 131072,
                                              :heartbeat => 0)

        send Protocol::Connection::Open.new(:virtual_host => '/',
                                            :capabilities => '',
                                            :insist => false)

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
        data = "this is a test!"

        send Protocol::Basic::Publish.new(:ticket => @ticket,
                                          :exchange => '',
                                          :routing_key => 'test_route'), :channel => 1
        send Protocol::Header.new(Protocol::Basic, data.length, :content_type => 'application/octet-stream',
                                                                :delivery_mode => 1,
                                                                :priority => 0), :channel => 1
        send Frame::Body.new(data), :channel => 1
      end
    end
  end
end

EM.run{
  AMQP.logging = true
  AMQP.client = SimpleClient
  AMQP.start
}