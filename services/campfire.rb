class Service::Campfire < Service
  class << self
    attr_accessor :campfire_class
  end

  self.campfire_class = Tinder::Campfire

  string :subdomain, :room, :token
  boolean :master_only, :play_sound, :long_url

  def receive_push
    url = data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)
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
    return unless opened?

    messages = []

    begin
      messages  = [
        "%s wants someone to merge %d %s into %s from %s:\n%s\n%s\n%s" % [
          pull.user.login,
          pull.commits,
          pull.commits == 1 ? :commit : :commits,
          pull.base.label, pull.head.label,
          pull.title, pull.body, pull.html_url
        ]
      ]
    rescue
      raise_config_error "Unable to build message: #{$!.to_s}"
    end

    send_messages messages
  end

  def receive_issues
    return unless opened?

    messages = []

    begin
      messages  = [
        "New issue on %s by %s: %s\n%s\n%s" % [
          "#{repo.owner.login}/#{repo.name}",
          issue.user.login,
          issue.title, issue.body, issue.html_url
        ]
      ]
    rescue
      raise_config_error "Unable to build message: #{$!.to_s}"
    end

    send_messages messages
  end

  def send_messages(messages)
    raise_config_error 'Missing campfire token' if data['token'].to_s.empty?

    return if data['master_only'].to_i == 1 and branch_name != 'master'

    play_sound = data['play_sound'].to_i == 1

    unless room = find_room
      raise_config_error 'No such campfire room'
    end

    messages.each { |line| room.speak line }
    room.play "rimshot" if play_sound && room.respond_to?(:play)
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

  def find_room
    room = campfire.find_room_by_name(data['room'])
  rescue StandardError
  end
end
