service :mantis_bt do |data, payload|
  begin
    base_url = data['url'].chomp('/')
    full_url = "#{base_url}/plugin.php"

    #add page/action to payload
    payload['page'] = 'Source/checkin'

    Net::HTTP.post_form(URI.parse(full_url), payload)

  rescue Net::HTTPBadResponse => boom
    raise GitHub::ServiceConfigurationError, "Invalid configuration"
  end
end
