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
		hash = sha256.digest(payload.to_json + data['api_key'])
		
		result = http_post "api/scm_files", :payload => payload.to_json, :hash => hash, :source => :github
		
		verify_response(result)
	end
	def verify_response(res)
		case res.status
			when 200..299
			when 403, 401, 422 then raise_config_error("Invalid Credentials")
			when 404, 301, 302 then raise_config_error("Invalid YouTrack URL")
			else raise_config_error("HTTP: #{res.status}")
		end
	end
end
