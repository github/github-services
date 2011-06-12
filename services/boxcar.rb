class Service::Boxcar < Service
  def receive_push
    http_post \
      "http://providers.boxcar.io/github/%s" %
        [secrets['boxcar']['apikey']],
      :emails => data['subscribers'],
      :payload => JSON.generate(payload)
  end
end
