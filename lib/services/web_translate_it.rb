class Service::WebTranslateIt < Service
  string :api_key

  def receive_push
    http_post "https://webtranslateit.com/api/projects/#{data['api_key']}/refresh_files",
      :payload => generate_json(payload)
  end
end
