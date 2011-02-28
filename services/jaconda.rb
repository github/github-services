service :jaconda do |data, payload|
  throw :halt, [400, "Missing 'subdomain'"] if data['subdomain'].to_s == ''
  throw :halt, [400, "Missing 'room_id'"] if data['room_id'].to_s == ''
  throw :halt, [400, "Missing 'room_token'"] if data['room_token'].to_s == ''

  url = URI.parse("https://#{data['subdomain']}.jaconda.im/api/v2/rooms/#{data['room_id']}/notify/github.json")
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data({
    :payload => JSON.generate(payload),
    :digest => data['digest']
  })
  req.basic_auth data['room_token'], "x"
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  res = nil
  http.start { |http| res = http.request(req) }

  if res.is_a?(Net::HTTPSuccess)
    true
  else
    throw :halt, [res.code.to_i, res.body.to_s]
  end
end