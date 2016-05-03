class Service::Versioneye < Service::HttpPost

  string :api_key
  string :project_id

  default_events :push

  url "http://www.VersionEye.com"
  logo_url "https://www.VersionEye.com/images/versioneye_01.jpg"

  maintained_by :github => 'reiz'
  supported_by  :web    => 'https://twitter.com/VersionEye',
                :email  => 'support@versioneye.com'

  def receive_event
    http.headers['content-type'] = 'application/json'
    project_id = data['project_id'].to_s.strip
    api_key    = data['api_key'].to_s.strip
    domain     = "https://www.versioneye.com"
    endpoint   = "/api/v2/github/hook/#{project_id}?api_key=#{api_key}"
    url        = "#{domain}#{endpoint}"
    body       = generate_json( payload )
    http_post url, "#{body}"
  end

end
