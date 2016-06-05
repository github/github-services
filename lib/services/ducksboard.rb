class Service::Ducksboard < Service
  string :webhook_key

  default_events :push, :issues, :fork, :watch

  # don't feed more than 5 ducksboard webhook endpoints with an event
  DUCKS_MAX_KEYS = 5

  def receive_push
    # Build Ducksboard webhook urls from the webhook_key config param,
    # then send a JSON containing the event type and payload to such
    # url.

    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    body = http.params.merge(
      :content => generate_json(:event => event, :payload => payload))

    parse_webhook_key(data).each do |key|
      url = "https://webhooks.ducksboard.com/#{key}"
      http_post url, body
    end

  rescue EOFError
    raise_config_error "Invalid server response."
  end

  alias receive_issues receive_push
  alias receive_fork receive_push
  alias receive_watch receive_push

  def parse_webhook_key(data)
    # the webhook key param is required
    if !data['webhook_key']
      raise_config_error "Invalid webhook key"
    end

    # we accept many webhook keys separated by spaces, but never more
    # than DUCKS_MAX_KEYS
    keys = data['webhook_key'].split[0, DUCKS_MAX_KEYS].collect do |key|
      # we do accept ducksboard webhook urls from which the key
      # will be extracted
      if key =~ /^https\:\/\/webhooks\.ducksboard\.com\//
        key = URI.parse(key).path[1..-1]
      end

      # only alphanumeric hex keys are valid
      if key !~ /^[a-fA-F0-9]+$/
        raise_config_error "Invalid webhook key"
      end

      key
    end

    keys
  end

end
