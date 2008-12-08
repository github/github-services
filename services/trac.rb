service :trac do |data, payload|
    url = data['url']
    # This is the API Token that is set in your trac.ini
    api_token = data['apitoken']
    # Build the URL
    # This should build a URL like this:
    #       http://yourserver.com/projects/myapp/github/APITOKEN
    url = URI.join(url, "/github/", api_token)
    # Send the request..
    Net::HTTP.post_form(url, payload)
end
