class Service::Crocagile < Service::HttpPost
  string :project_key
  url "https://www.crocagile.com/home"
  logo_url "https://www.crocagile.com/_images/crocagile100x100t.png"
  maintained_by :github => 'noelbaron',
    :twitter => 'noelbaron'
  supported_by :web => 'https://www.crocagile.com/home',
    :email => 'support@crocagile.com',
    :twitter => 'crocagilehelp'

  def receive_event
    raise_config_error "Please enter your Project Key (located via Project Settings screen)." if data['project_key'].to_s.empty?
    http.headers['Content-Type'] = 'application/json'
    deliver "https://www.crocagile.com/api/integration/github"
  end
end
