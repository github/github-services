class Service::CleverCloud < Service
  include HttpHelper

  self.title = 'Clever Cloud'

  password :secret

  default_events  :push

  url "https://www..clever-cloud.com/"
  logo_url "http://cleverstatic.cleverapps.io/twitter-cards-assets/tw-card-logo.png"
  maintained_by :github => 'Keruspe'
  supported_by :web => 'https://www.clever-cloud.com/',
               :email => 'support@clever-cloud.com'

  def receive_push
    secret_ok = required_config_value ("secret")

    http.headers['X-GitHub-Event'] = event.to_s
    http.headers['X-GitHub-Delivery'] = delivery_guid.to_s

    res = deliver 'https://api.clever-cloud.com/v2/github/redeploy/', :content_type => 'application/json', :secret => secret_ok

    if res.status < 200 || res.status > 299
      raise_config_error "Invalid HTTP Response: #{res.status}"
    end
  end

  def original_body
    payload
  end
end
