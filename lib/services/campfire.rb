class Service::Campfire < Service
  class << self
    attr_accessor :campfire_class
  end

  self.campfire_class = Tinder::Campfire

  string :subdomain, :room, :sound
  password :token
  boolean :master_only, :play_sound, :long_url
  white_list :subdomain, :room

  default_events :push, :pull_request, :issues

  def receive_push
    url = configured_summary_url
    messages = []
    messages << "#{summary_message}: #{url}"
    messages += commit_messages.first(8)

    if messages.first =~ /pushed 1 new commit/
      messages.shift # drop summary message
      messages.first << " ( #{distinct_commits.first['url']} )"
    end

    send_messages messages
  end

  def receive_pull_request
    message = "#{summary_message}: #{configured_summary_url}"
    send_messages message if action =~ /(open)|(close)/
  end

  alias receive_issues receive_pull_request

  def receive_public
    send_messages "#{summary_message}: #{configured_summary_url}"
  end

  alias receive_gollum receive_public

  def send_messages(messages)
    raise_config_error 'Missing campfire token' if data['token'].to_s.empty?

    return if data['master_only'].to_i == 1 && respond_to?(:branch_name) && branch_name != 'master'

    play_sound = data['play_sound'].to_i == 1
    sound = data['sound'].blank? ? 'rimshot' : data['sound']

    unless room = find_room
      raise_config_error 'No such campfire room'
    end

    Array(messages).each { |line| room.speak line }
    room.play sound if play_sound && room.respond_to?(:play)
  rescue OpenSSL::SSL::SSLError => boom
    raise_config_error "SSL Error: #{boom}"
  rescue Tinder::AuthenticationFailed => boom
    raise_config_error "Authentication Error: #{boom}"
  rescue Faraday::Error::ConnectionFailed
    raise_config_error "Connection refused- invalid campfire subdomain."
  end

  attr_writer :campfire
  def campfire
    @campfire ||= self.class.campfire_class.new(campfire_domain, :ssl => true, :token => data['token'])
  end

  def campfire_domain
    data['subdomain'].to_s.sub /\.campfirenow\.com$/i, ''
  end

  def configured_summary_url
    data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)
  end

  def find_room
    room = campfire.find_room_by_name(data['room'])
  rescue StandardError
  end
end
