service :commitify do |data, payload|
  # Private key (for private repositories, share with your developers)
  private_key = data['private_key']
  
  Net::HTTP.post_form(URI.parse("http://commitify.appspot.com/commit"), :key => private_key, :payload => JSON.generate(payload))
end
