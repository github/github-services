service :read_the_docs do |data, payload|
  Net::HTTP.post_form(URI.parse("http://readthedocs.org/github"), :payload => JSON.generate(payload))
end

