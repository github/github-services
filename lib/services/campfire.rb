class Service::Campfire < Service::HttpPost

  attr_accessor :original_body

  string :subdomain, :room, :token, :sound
  boolean :master_only, :play_sound, :long_url
  white_list :room_id, :subdomain

  default_events :push, :pull_request, :issues

  supported_by :email   => 'email@37signals.com',
               :twitter => '@37Signals',
               :web     => 'http://help.37signals.com/campfire'

  url 'https://campfirenow.com'
  logo_url 'https://campfirenow.com/images/logo_campfire-full.png'

  def recieve_event
    return if data['master_only'].to_i == 1 && respond_to?(:branch_name) && branch_name != 'master'
    speak "#{ summary_message }: #{ configured_summary_url }"
    make_some_noise if data['play_sound'].to_i == 1
  end

private

  def configured_summary_url
    data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)
  end

  def make_some_noise
    sound = data['sound'].blank? ? 'rimshot' : data['sound']
    original_body = { :message => { :body => sound }, type: 'sound' }
    deliver room_url
  end

  def room_url
    @room_url ||= build_room_url
  end

  def build_room_url
    room_id   = required_config_value 'room_id'
    token     = required_config_value 'token'
    subdomain = required_config_value 'subdomain'

    "https://#{ token }:x@#{ subdomain }.campfirenow.com/room/#{ room_id }/speak"
  end

  def speak body
    original_body = { :message => { :body => body }}
    deliver room_url
  end

end
