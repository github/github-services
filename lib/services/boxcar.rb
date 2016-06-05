class Service::Boxcar < Service
  string :subscribers
  white_list :subscribers

  def receive_push
    http_post \
      "http://providers.boxcar.io/github/%s" %
        [secrets['boxcar']['apikey']],
      :emails => data['subscribers'],
      :payload => generate_json(payload)
  end
end
