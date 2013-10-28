class Service::SensioLabsInsight < Service
  string :user_uuid, :api_token
  white_list :user_uuid

  def receive_push
    http.ssl[:verify] = false
    http_post sl_insight_url, :payload => generate_json(payload)
  end

  def sl_insight_url
    "https://insight.sensiolabs.com/api/analyze-scm?userUuid=#{user_uuid}&apiToken=#{api_token}"
  end

  def user_uuid
    data['user_uuid'].strip
  end

  def api_token
    data['api_token'].strip
  end
end

