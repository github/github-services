class Service::GitBook < Service::HttpPost
  string :username, :api_token, :book_id

  default_events :push

  url "https://www.gitbook.io"
  logo_url "https://www.gitbook.io/assets/images/logo/128.png"

  maintained_by :github => 'SamyPesse',
    :twitter => '@SamyPesse'

  supported_by :web => 'https://www.gitbook.io',
    :email => 'contact@gitbook.io',
    :twitter => '@GitBookIO'

  def receive_event
    username = required_config_value('username')
    api_token = required_config_value('api_token')
    book_id = required_config_value('book_id')

    if username.match(/^[A-Za-z0-9_-]+$/) == nil
      raise_config_error "Invalid username"
    end

    if api_token.match(/^[A-Za-z0-9_-]+$/) == nil
      raise_config_error "Invalid api token"
    end

    if book_id.match(/^[A-Za-z0-9_-]+\/[A-Za-z0-9_-]+$/) == nil
      raise_config_error "Invalid book id"
    end

    url = "https://push.gitbook.io/github?token=#{api_token}&username=#{username}&book=#{book_id}"
    deliver url
  end
end
