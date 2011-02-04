service :hip_chat do |data, payload|
  # make sure we have what we need
  throw :halt, [400, "Missing 'auth_token'"] if data['auth_token'].to_s == ''
  throw :halt, [400, "Missing 'room'"] if data['room'].to_s == ''

  req = Net::HTTP::Post.new("/v1/webhooks/github")
  req.set_form_data({
    :auth_token => data['auth_token'],
    :room_id => data['room'],
    :payload => JSON.generate(payload),
    :notify => data['notify'] ? 1 : 0
  })
  req["Content-Type"] = 'application/x-www-form-urlencoded'

  http = Net::HTTP.new("api.hipchat.com", 443)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  begin
    http.start do |connection|
      connection.request(req)
    end
  rescue Net::HTTPBadResponse
    raise GitHub::ServiceConfigurationError, "Invalid configuration"
  end

  # Sinatra expects a string return
  "Great success!"
end
