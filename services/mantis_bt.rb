service :mantis_bt do |data, payload|
  begin
    url_value = data['url'].chomp('/')
    url = "#{url_value}/plugin.php?page=Source/checkin"
    Net::HTTP.post_form(URI.parse(url), "payload" => payload.to_json)
  rescue Net::HTTPBadResponse => boom
    raise GitHub::ServiceConfigurationError, "Invalid configuration"
  rescue Errno::ECONNREFUSED => boom
    raise GitHub::ServiceConfigurationError, "Connection refused. Invalid server URL."
  end
end
