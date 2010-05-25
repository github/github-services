service :hip_chat do |data, payload|
  # make sure we have what we need
  throw :halt, [400, "Missing auth_token"] if data['auth_token'].to_s == ''
  throw :halt, [400, "Missing room"] if data['room'].to_s == ''

  # send it
  url = URI.parse("http://api.hipchat.com/v1/rooms/message_github")
  Net::HTTP.post_form(url, {
    :auth_token => data['auth_token'],
    :room_id => data['room'],
    :payload => JSON.generate(payload),
  })

  # Sinatra expects a string return
  "Great success!"
end
