class Service::Codeship < Service
  string :project_uuid

  url "http://www.codeship.io"
  logo_url "http://www.codeship.io/assets/logo_codeship_topbar.png"

  maintained_by :github => 'clemenshelm'
  supported_by  :web => 'http://www.codeship.io/contact',
                :email => 'clemens@codeship.io'

  def receive_push
    http.headers['content-type'] = 'application/json'
    http_post codeship_url, generate_json(payload)
  end

  private

  def codeship_url
    "https://www.codeship.io/hook/#{data['project_uuid']}"
  end
end
