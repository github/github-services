class Service::WebTranslateIt < Service
  def receive_push
    http_post "https://webtranslateit.com/api/projects/#{data['api_key']}/refresh_files",
      :payload => JSON.generate(payload)
  end
end
