class Service::Ducksboard < Service
  string :webhook_key

  def receive_push
    # As simple as it can get: just build a ducksboard webhooks url from
    # the webhook_key config param and send the whole payload, ducksboard
    # will know what to do with it.
    # Why not using a POST-receive url then? Because we are interested in
    # more events than just pushes!

    # webhook key sanity check
    webhook_key = check_webhook_key(data)

    url = "https://webhooks.ducksboard.com/#{webhook_key}"

    http.headers['content-type'] = 'application/x-www-form-urlencoded'
    body = Faraday::Utils.build_nested_query(
      http.params.merge(:payload => JSON.generate(payload)))

    http_post url, body

  rescue EOFError
    raise_config_error "Invalid server response."
  end

  alias receive_issues receive_push
  alias receive_fork receive_push
  alias receive_watch receive_push

  def check_webhook_key(data)
    # the webhook key is required
    if !data['webhook_key']
      raise_config_error "Invalid webhook key"
    end

    # we do accept ducksboard webhook urls from which the key will be extracted
    webhook_key = data['webhook_key']
    if webhook_key =~ /^https\:\/\/webhooks\.ducksboard\.com\//
      webhook_key = URI.parse(webhook_key).path[1..-1]
    end

    # only alphanumeric hex keys are valid
    if webhook_key !~ /^[a-fA-F0-9]+$/
      raise_config_error "Invalid webhook key"
    end

    webhook_key
  end

end
