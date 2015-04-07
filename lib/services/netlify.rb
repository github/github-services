class Service::Netlify < Service
  include HttpHelper

  self.title = "Netlify"

  url "https://www.netlify.com"
  logo_url "https://www.netlify.com/favicon.ico"

  maintained_by :github => 'netlify'
  supported_by  :web => 'https://www.netlify.com/contact',
    :email => 'support@netlify.com'

  string :url

  default_events :push, :pullrequest

  def receive_event
    http.headers['X-GitHub-Event'] = event.to_s
    http.headers['X-GitHub-Delivery'] = delivery_guid.to_s

    res = deliver data['url']

    if res.status < 200 || res.status > 299
      raise_config_error "Invalid HTTP Response: #{res.status}"
    end
  end

  alias :original_body :payload
end
