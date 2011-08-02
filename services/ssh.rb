class Service::Ssh < Service
  def receive_push  	
  	require 'net/ssh'
  	Net::SSH.start(data['host'], data['user'], :port => data['port'], :key_data =>["-----BEGIN RSA PRIVATE KEY-----\n"+data['key'].gsub!(" ", "+")+"-----END RSA PRIVATE KEY-----"])  		
  end
end