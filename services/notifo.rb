secrets = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'secrets.yml'))

service :notifo do |data, payload|

  subscribe_url = URI.parse('https://api.notifo.com/v1/subscribe_user')
  data['subscribers'].gsub(/\s/, '').split(',').each do |subscriber|
    req = Net::HTTP::Post.new(subscribe_url.path)
    req.basic_auth('github', secrets['notifo']['apikey'])
    req.set_form_data('username' => subscriber)
    net = Net::HTTP.new(subscribe_url.host, 443)
    net.use_ssl = true
    net.verify_mode = OpenSSL::SSL::VERIFY_NONE
    net.start {|http| http.request(req)}

    notification_url = URI.parse('https://api.notifo.com/v1/send_notification')
    commit = payload['commits'].last;
    req = Net::HTTP::Post.new(notification_url.path)
    req.basic_auth('github', secrets['notifo']['apikey'])
    if payload['commits'].length > 1
      extras = payload['commits'].length - 1
      req.set_form_data(
        'to' => subscriber,
        'msg' => URI.escape("#{commit['author']['name']}:  \"#{commit['message'].slice(0,40)}\" (+#{extras} more commits)", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
        'title' => URI.escape("#{payload['repository']['name']}/#{payload['ref_name']}", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
        'uri' => URI.escape(payload['compare'], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      )
    else
      req.set_form_data(
        'to' => subscriber,
        'msg' => URI.escape("#{commit['author']['name']}:  \"#{commit['message']}\"", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
        'title' => URI.escape("#{payload['repository']['name']}/#{payload['ref_name']}", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")),
        'uri' => URI.escape(commit['url'], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      )
    end
    net = Net::HTTP.new(notification_url.host, 443)
    net.use_ssl = true
    net.verify_mode = OpenSSL::SSL::VERIFY_NONE
    net.start {|http| http.request(req)}
  end

end
