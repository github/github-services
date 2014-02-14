class Service::ChatWork < Service
  include HttpHelper

  string :auth_token, :room_id

  url 'https://www.chatwork.com/'

  logo_url 'http://www.chatwork.com/ja/download/logo/logotype_simple_bgnone_blue.png'

  maintained_by :github => 'alpaca-tc', :twitter => '@alpaca_taichou'

  supported_by :github => 'alpaca-tc'

  default_events :commit_comment, :issues, :issue_comment,
    :pull_request, :pull_request_review_comment, :push

  def receive_event
    send_message case event
    when :commit_comment, :issue_comment
      comment_message
    when :pull_request_review_comment
      pull_request_review_comment_message
    when :pull_request
      pull_request_message
    else
      <<-MESSAGE.gsub(/^\s*/, '')
      #{summary_message}
      #{summary_url}
      MESSAGE
    end
  end

  private

  def comment_message
    header = summary_message.split(/:/).first

    <<-MESSAGE.gsub(/^\s*/, '')
    #{header}
    #{comment['body']}
    #{summary_url}
    MESSAGE
  end

  def pull_request_message
    base_ref = pull.base.label.split(':').last
    head_ref = pull.head.label.split(':').last
    head_ref = pull.head.label if head_ref == base_ref

    <<-MESSAGE.gsub(/^\s*/, '')
    #{action} a pull request, #{pull.title} (#{base_ref}..#{head_ref})
    #{pull.html_url}
    MESSAGE
  end

  def pull_request_review_comment_message
    header = summary_message.split(/\s*\h+:/).first

    <<-MESSAGE.gsub(/^\s*/, '')
    #{header}
    #{comment['body']}
    #{summary_url}
    MESSAGE
  end

  def send_message(message)
    message = "- #{message}"

    http.headers['X-ChatWorkToken'] = required_config_value('auth_token')
    http_post(chatwork_url, body: message)
  end

  def chatwork_url
    @chatwork_url ||= begin
      room_id = required_config_value('room_id')
      "https://api.chatwork.com:443/v1/rooms/#{room_id}/messages"
    end
  end
end
