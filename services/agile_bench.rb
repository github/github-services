class Service::AgileBench < Service
  string :token, :project_id

  def receive_push
    token, project_id =
     data['token'].to_s.strip, data['project_id'].to_s.strip

    raise_config_error "Invalid Token" if !token.present?
    raise_config_error "Invalid Project ID" if !project_id.present?

    response = { :token       => token,
                 :payload     => payload }

    puts "response: " + response.to_json

    res = http_post "http://212.127.65.121:9393/project/#{project_id}",
      { :data => response.to_json }
  end
end

