class Service::Versioneye < Service

  string :api_key
  string :project_id

  url "http://www.VersionEye.com"
  logo_url "https://www.VersionEye.com/images/versioneye_01.jpg"

  maintained_by :github => 'reiz'
  supported_by  :web    => 'https://twitter.com/VersionEye',
                :email  => 'support@versioneye.com'

  def receive_push
    http.headers['content-type'] = 'application/json'
    http_get( "https://www.versioneye.com/api/v2/github/hook/#{data['project_id']}?api_key=#{data['api_key']}" )
  end

end
