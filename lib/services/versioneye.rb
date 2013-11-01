class Service::VersionEye < Service

  string :api_key
  string :project_id

  url "http://www.versioneye.com"
  logo_url "https://www.versioneye.com/images/versioneye_01.jpg"

  maintained_by :github => 'reiz'
  supported_by  :web    => 'https://twitter.com/VersionEye',
                :email  => 'support@versioneye.com'

  def receive_push
    http.headers['content-type'] = 'application/json'
    http_get versioneye_hook
  end

  private

    def versioneye_hook
      "https://www.versioneye.com/hook/#{data['project_id']}?api_key=#{data['api_key']}"
    end

end
