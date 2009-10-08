service :rdocinfo do |data, payload|
  Net::HTTP.post_form(URI.parse("http://rdoc.info/projects/update"), :payload => JSON.generate(payload))
  "namaste"
end
