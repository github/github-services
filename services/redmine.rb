service :redmine do |data, payload|
    url = URI.join(data['address'], "sys/fetch_changesets?key=#{URI.escape(data['api_key'])}&id=#{URI.escape(data['project'])}")
    if (url.scheme == "http")
        Net::HTTP.get(url)
    elsif (url.scheme == "https")
        # HTTPS
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url.request_uri)
        http.start{|http| http.request(request)}
    else
        # do nothing
    end 
end

