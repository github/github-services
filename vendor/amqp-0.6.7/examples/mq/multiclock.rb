$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'mq'
require 'time'

AMQP.start(:host => 'localhost') do

  def log *args
    p args
  end

  #AMQP.logging = true

  clock = MQ.new.headers('multiformat_clock')
  EM.add_periodic_timer(1){
    puts

    time = Time.new
    ["iso8601","rfc2822"].each do |format|
      formatted_time = time.send(format)
      log :publish, format, formatted_time
      clock.publish "#{formatted_time}", :headers => {"format" => format}
    end
  }

  ["iso8601","rfc2822"].each do |format|
    amq = MQ.new
    amq.queue(format.to_s).bind(amq.headers('multiformat_clock'), :arguments => {"format" => format}).subscribe{ |time|
      log "received #{format}", time
    }
  end

end

__END__

[:publish, "iso8601", "2009-02-13T19:55:40-08:00"]
[:publish, "rfc2822", "Fri, 13 Feb 2009 19:55:40 -0800"]
["received iso8601", "2009-02-13T19:55:40-08:00"]
["received rfc2822", "Fri, 13 Feb 2009 19:55:40 -0800"]

[:publish, "iso8601", "2009-02-13T19:55:41-08:00"]
[:publish, "rfc2822", "Fri, 13 Feb 2009 19:55:41 -0800"]
["received iso8601", "2009-02-13T19:55:41-08:00"]
["received rfc2822", "Fri, 13 Feb 2009 19:55:41 -0800"]

[:publish, "iso8601", "2009-02-13T19:55:42-08:00"]
[:publish, "rfc2822", "Fri, 13 Feb 2009 19:55:42 -0800"]
["received iso8601", "2009-02-13T19:55:42-08:00"]
["received rfc2822", "Fri, 13 Feb 2009 19:55:42 -0800"]