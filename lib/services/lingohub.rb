class Service::Lingohub < Service

  url "https://lingohub.com"
  logo_url "https://lingohub.com/assets/public/press/media_kit/lingohub_logo.jpg"

  maintained_by :github => 'lingohub'

  supported_by :web => 'http://support.lingohub.com',
               :email => 'support@lingohub.com'

  default_events :push
  password :project_token

  def receive_push
    project_token = data['project_token']

    if project_token.nil?
      raise_config_error "You have to specify a Project Token"
    end

    res = http_post "http://lingohub.com/github_callback?auth_token=#{project_token}",
                    :payload => generate_json(payload)

    if res.status < 200 || res.status > 299
      raise_config_error res.body
    end
  end
end
