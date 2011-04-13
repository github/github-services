service :masterbranch do |data,payload|
	# fail fast with no token
	
	url = URI.parse("http://192.168.1.33:9003/gh-hook")
	
	req = Net::HTTP::Post.new(url.path)
	
	req.set_form_data({'payload' => JSON.generate(payload)})
	puts "sending a commit"
	http = Net::HTTP.new(url.host, url.port)
	http.use_ssl = true if url.port == 443 || url.instance_of?(URI::HTTPS)
	http.start { |http| http.request(req)}			
	
end

