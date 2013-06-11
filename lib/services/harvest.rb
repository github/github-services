require 'base64'
require 'bigdecimal'
require 'date'
require 'jcode' if RUBY_VERSION < '1.9'
require 'time'
require 'rexml/document'

class Service::Harvest < Service
  string    :subdomain, :username
  password  :password
  boolean   :ssl
  white_list :subdomain, :username

  def receive_push
    if data['username'].to_s.empty?
      raise_config_error "Needs a username"
    end
    if data['password'].to_s.empty?
      raise_config_error "Needs a password"
    end

    http.basic_auth(data['username'], data['password'])
    http.headers['Content-Type'] = 'application/xml'
    http.headers['Accept'] = 'application/xml'
    http.url_prefix = "http#{:s if data['ssl']}://#{data['subdomain']}.harvestapp.com/"

    statuses   = []
    repository = payload['repository']['name']

    payload['commits'].each do |commit|
      author = commit['author'] || {}
      tiny_url = shorten_url(commit['url'])
      statuses << "[#{repository}] #{tiny_url} #{author['name']} - #{commit['message']}"
    end

    messages = messages_from_daily statuses * "\n"

    timer, message = messages.last
    http_post "daily/update/#{timer}", message if timer
  end

  # Gets the daily day entries, and builds the xml payload for the timer update api.
  #
  # status - String message build from the commit messages of the push.
  #
  # Returns an Array of [timer, String xml message] tuples for each day entry.
  def messages_from_daily(status)
    daily = http_get 'daily'
    doc   = REXML::Document.new(daily.body)
    messages = []
    doc.elements.each('daily/day_entries/day_entry') do |ele|
      if ele.elements['timer_started_at']
        messages << [ele.elements['id'].text, 
          "<request><notes>#{ele.elements['notes'].text}\n#{status}</notes><hours>#{ele.elements['hours'].text}</hours></request>"]
      end
    end
    messages
  end
end
