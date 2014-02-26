class Service::Pushbullet < Service
  string :api_key, :device_iden

  default_events :push, :issues, :pull_request

  url "https://www.pushbullet.com/"
  logo_url "https://lh3.ggpht.com/hlxRPX7B5J28cgGAZcovaT-7wLimLi0wPi7dSI6udH5NGI58WTBezGgpJyIepZhBRp4=w500"

  maintained_by :github => 'tuhoojabotti',
    :twitter => 'tuhoojabotti',
    :web => 'http://tuhoojabotti.com/#contact'

  supported_by :web => 'https://www.pushbullet.com/help',
    :email => 'hey@pushbullet.com'

  def receive_push
    check_api_key

    return unless payload["commits"].any?

    p = convert_to_ostruct payload
    message = truncate_if_too_long p.commits.last["message"], 200
    repo    = p.repository

    if p.commits.length == 1
      title = "#{p.pusher.name} pushed to #{owner}/#{name}"
    else
      title   = "#{p.pusher.name} pushed #{p.commits.length} commits"
      message = "Repo: #{repo.owner.name}/#{repo.name}\nLatest: #{message}"
    end

    push_message title, message
  end

  def receive_issue
    check_api_key

    p = convert_to_ostruct payload
    i    = p.issue
    repo = p.repository

    body = truncate_if_too_long i.body, 200

    push_message "#{i.user.login} #{p.action} issue ##{i.number}",
      "Repo: #{repo.owner.login}/#{repo.name}\n" +
      "Issue: \"#{i.title}\"\n#{body}"
  end

  def receive_pull_request
    check_api_key

    p = convert_to_ostruct payload
    i    = p.pull_request
    repo = p.repository

    body = truncate_if_too_long i.body, 200

    push_message "#{i.user.login} #{p.action} pull request ##{i.number}",
      "Repo: #{repo.owner.login}/#{repo.name}\n" +
      "Pull Request: \"#{i.title}\"\n#{body}"
  end

  private

  def check_api_key
    raise_config_error "Invalid Pushbullet api key." unless data["api_key"]
  end

  def push_message(title, message)
    # set api key
    http.basic_auth(data["api_key"], "")

    # call api
    http_post "https://api.pushbullet.com:443/api/pushes",
      :device_iden => data["device_iden"],
      :type => "note",
      :title => title,
      :body => message
  end

  def convert_to_ostruct(obj)
    if obj.is_a? Hash
      obj.each  do |key, val|
        obj[key] = convert_to_ostruct val
      end
      obj = OpenStruct.new obj
    elsif obj.is_a? Array
       obj = obj.map { |r| convert_to_ostruct r }
    end
    return obj
  end

  def truncate_if_too_long(str, len)
    str.length > len ? str[0..len].gsub(/\s\w+\s*$/, '...') : str
  end
end