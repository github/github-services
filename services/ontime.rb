class Service::OnTime < Service
	string :ontime_url, :api_key
	
	def receive_push
		if data['ontime_url'].to_s.empty?
			raise_config_error "No OnTime URL to connect to."
		elsif data['api_key'].to_s.empty?
			raise_config_error "No API Key."
		end
		
		#We're just going to send back the entire payload and process it in OnTime.
		http.headers['Content-Type'] = 'application/json'
		http.url_prefix = data['ontime_url']
		
		#Hash the data
		sha256 = Digest::SHA2.new(256)
		hash = sha256.digest(payload.to_json + api_key)
		
		result = http_post "api/scm_files", :payload => payload.to_json, :hash => hash, :source => :github
		
		if(result.status != 200)
			raise_config_error "Post status returned: " + result.status
		end
	end
end