service :trac do |data, payload|
    #The data['url'] may contain a subdirectory, so this fails
    #url = URI.join(data['url'], '/github/', data['token'])
    url_value = data['url'].chomp('/')
    url = "#{url_value}/github/#{data['token']}"
    Net::HTTP.post_form(URI.parse(url), payload)
end
