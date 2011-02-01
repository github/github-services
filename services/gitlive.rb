service :gitlive do |data, payload|
  provider_url = URI.parse("http://gitlive.com/hook")
  Net::HTTP.post_form(provider_url, 
    {:payload => JSON.generate(payload)})
end