$:.unshift File.dirname(__FILE__) + '/../../lib'
require 'mq'

AMQP.start(:host => 'localhost') do

  def log *args
    p args
  end

  # AMQP.logging = true

  class HashTable < Hash
    def get key
      log 'HashTable', :get, key
      self[key]
    end
    
    def set key, value
      log 'HashTable', :set, key => value
      self[key] = value
    end

    def keys
      log 'HashTable', :keys
      super
    end
  end

  server = MQ.new.rpc('hash table node', HashTable.new)

  client = MQ.new.rpc('hash table node')
  client.set(:now, time = Time.now)
  client.get(:now) do |res|
    log 'client', :now => res, :eql? => res == time
  end

  client.set(:one, 1)
  client.keys do |res|
    log 'client', :keys => res
    AMQP.stop{ EM.stop }
  end

end

__END__

["HashTable", :set, {:now=>Thu Jul 17 21:04:53 -0700 2008}]
["HashTable", :get, :now]
["HashTable", :set, {:one=>1}]
["HashTable", :keys]
["client", {:eql?=>true, :now=>Thu Jul 17 21:04:53 -0700 2008}]
["client", {:keys=>[:one, :now]}]