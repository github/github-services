class Service::Ducksboard < Service
  string :webhook_key

  default_events :push, :issues, :fork, :watch

  # don't feed more than 5 ducksboard webhook endpoints with an event
  DUCKS_MAX_KEYS = 5

  def receive_push
    # As simple as it can get: just build a ducksboard webhooks url from
    # the webhook_key config param and send the whole payload, ducksboard
    # will know what to do with it.
    # Why not using a POST-receive url then? Because we are interested in
    # more events than just pushes!

    # webhook keys extraction and sanity check
    webhook_keys = parse_webhook_key(data)

    webhook_keys.each do |key|
      url = "https://webhooks.ducksboard.com/#{key}"

      http.headers['content-type'] = 'application/x-www-form-urlencoded'
      body = http.params.merge(:payload => JSON.generate(payload))

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
