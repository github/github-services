class Service::Circleci < Service
  self.title = "CircleCI"
  url "https://circleci.com"
  logo_url "https://circleci.com/favicon.ico"

  maintained_by :github => 'circleci'
  supported_by  :web => 'https://circleci.com/about',
    :email => 'sayhi@circleci.com'

  default_events Service::ALL_EVENTS

  string :domain
  white_list :domain

  def receive_event
    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    http_post circleci_url,
      "payload" => generate_json(payload),
      "event_type" =>  generate_json(:event_type => event)
  end

  private

  def circleci_url
    "#{domain}/hooks/github"
  end

  def domain
      if data['domain'].present?
          data['domain'].sub(%r{/+$}, '')
      else
          'https://circleci.com'
      end
  end
end
