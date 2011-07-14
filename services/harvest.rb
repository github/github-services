require 'base64'
require 'bigdecimal'
require 'date'
require 'jcode'
require 'net/http'
require 'net/https'
require 'time'
require 'rexml/document'

class Service::Harvest < Service
  string    :subdomain, :username
  password  :password
  boolean   :ssl

  def receive_push
    if data['username'].to_s.empty?
      raise_config_error "Needs a username"
    end
    if data['password'].to_s.empty?
      raise_config_error "Needs a password"
    end

    @connection = Net::HTTP.new("#{data['subdomain']}.harvestapp.com", data['ssl'] ? 443 : 80)
    @connection.use_ssl = true

    statuses   = [ ]
    repository = payload['repository']['name']

    if data['digest'] == '1'
      commit = payload['commits'][-1]
      author = commit['author'] || {}
      tiny_url = shorten_url(payload['repository']['url'] + '/commits/' + payload['ref_name'])
      status = "[#{repository}] #{tiny_url} #{author['name']} - #{payload['commits'].length} commits"
      statuses << status
    else
      payload['commits'].each do |commit|
        author = commit['author'] || {}
        tiny_url = shorten_url(commit['url'])
        status = "[#{repository}] #{tiny_url} #{author['name']} - #{commit['message']}"
        statuses << status
      end
    end

    build_message = ""

    statuses.each do |status|
      build_message = "#{status}\n"
    end
    final_message = get_daily(build_message)
    post(final_message) if @timer_on
  end

  def headers
    {
      "Accept"  =>  "application/xml",
      "Content-Type" => "application/json",
      "Authorization" => "Basic #{auth_string}"
    }
  end

  def auth_string
    Base64.encode64("#{data['username']}:#{data['password']}").delete("\r\n")
  end

  def get_daily(builder)
    daily = @connection.get('/daily', headers)
    doc = REXML::Document.new(daily.body)
    message = ""
    doc.elements.each('daily/day_entries/day_entry') do |ele|
      if ele.elements['timer_started_at']
        @timer_on = ele.elements['id'].text
        message = "<request><notes>#{builder}\n#{ele.elements['notes'].text}</notes><hours>#{ele.elements['hours'].text}</hours></request>"
      end
    end
    return message
  end

  def post(status)
    http.basic_auth(data['username'], data['password'])
    http.headers['Content-Type'] = 'application/xml'
    http.headers['Accept'] = 'application/xml'
    http.url_prefix = "https://#{data['subdomain']}.harvestapp.com/"
    http_post "daily/update/#{@timer_on}", status
  end
end
