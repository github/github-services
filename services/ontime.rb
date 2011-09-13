class Service::OnTime < Service
	string :ontime_url, :api_key
	
	def receive_push
		if data['ontime_url'].to_s.empty?
			raise_config_error "No OnTime URL to connect to."
		elsif data['api_key'].to_s.empty
			raise_config_error "No API Key."
		end
		
		
	end
end