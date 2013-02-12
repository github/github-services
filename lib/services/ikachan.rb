require 'services/irc'

class Service::Ikachan < Service::IRC
  string :url, :room

  def send_messages(messages)
    base_url = URI.parse(data['url'])
    channel  = data['channel']

    join_url   = URI.join(base_url.to_s, '/join')
    notice_url = URI.join(base_url.to_s, '/notice')

    messages = Array(messages)

    rooms = data['room'].to_s
    if rooms.empty?
      raise_config_error "No rooms: #{rooms.inspect}"
      return
    end

    rooms = rooms.gsub(",", " ").split(" ").map{|room| room[0].chr == '#' ? room : "##{room}"}

    rooms.each do |room|
      http_post join_url, { 'channel' => room }
      messages.each do |message|
        http_post notice_url, { 'channel' => room, 'message' => message }
      end
    end
  end

end
