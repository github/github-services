class Service::Heroku_DeployBot < Service

  string :heroku_apps

  white_list :heroku_apps

  default_events :push

  url "http://deploybot.abhishekmunie.com"
  maintained_by :github => 'abhishekmunie'
  supported_by :web => 'https://github.com/abhishekmunie/deploybot/wiki',
    :email => 'bot@abhishekmunie.com'

  def receive_push
    return unless payload['commits']

    raise_config_error "Needs heroku app name." if data['heroku_apps'].to_s.empty?

    http.headers['Content-Type'] = 'application/json'

    # Uses this URL as a prefix for every request.
    http.url_prefix = "https://deploybot.herokuapp.com"

    if data['heroku_apps'].respond_to?("each")
      heroku_apps.each do |heroku_app|
        # POST https://deploybot.heroku.com/:heroku_app
        http_post heroku_app
      end
    else
      http_post heroku_apps
    end
  end
end