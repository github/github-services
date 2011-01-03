
service :geocommit do |data, payload|

    url = URI.parse('http://hook.geocommit.com/api/github')
    req = Net::HTTP::Post.new(url.path)
    req.body = JSON.generate(payload)
    req.set_content_type('application/githubpostreceive+json')
    Net::HTTP.new(url.host, url.port).start {|http| http.request(req)}

end
