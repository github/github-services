class Service::IDoneThis < Service
  string :team_name, :token

  white_list :team_name

  default_events :push, :issues, :issue_comment, :gollum

  url "https://idonethis.com"
  logo_url "http://media.tumblr.com/c81110ba7abfebb4c2a97062eada69c7/tumblr_inline_mimshfCodO1qhg0wt.png"

  maintained_by :github => 'aedoran',
    :twitter => '@aedoran'

  supported_by :web => 'https://idonethis.com/help/',
    :email => 'help@idonethis.com',
    :twitter => '@idonethis'

  def receive_event

    raise_config_error 'Missing token' if data['token'].to_s.empty?
    raise_config_error 'Missing team name' if data['team_name'].to_s.empty?

    token = data['token']
    team_name = data['team_name']


    http.headers['Authorization'] = "#{token}"

    http.url_prefix = "https://idonethis.com/gh/"

    http_post team_name+"/?token="+token, generate_json(:payload => payload,:event => event)

  end
end
