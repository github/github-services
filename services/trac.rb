service :trac do |data, payload|
    url = URI.parse(data['url'])
    # Need to get the GitHub API Token here..
    api_token = "NEED TO GET THIS.."
    # Build the URL
    url = "#{url}/github/#{api_token}"
    # Send the request..
    Net::HTTP.post_form(url, payload)
end
