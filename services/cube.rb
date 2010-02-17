service :cube do |data, payload|
    url = URI.parse("http://cube.bitrzr.com/integration/events/github/create")
    
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data('payload' => JSON.generate(payload), 
                      'project_name' => data['project'], 
                      'project_token' => data['token'], 
                      'domain' => data['domain'])
    Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
end
