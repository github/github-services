service :rubydocinfo do |data, payload|
  Net::HTTP.post_form(URI.parse("http://rubydoc.info/checkout"), :payload => JSON.generate(payload))
  "namaste"
end
