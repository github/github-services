class Service::Datadog < Service::HttpPost
  ## Company stuff
  url 'https://app.datadoghq.com'
  logo_url 'https://www.datadoghq.com/favicon.ico'

  maintained_by :github => 'miketheman',
                :twitter => '@mikefiedler'
  # Support channels for user-level Datadog submission problems (service
  # failure, misconfigured keys, etc)
  supported_by :web => 'http://help.datadoghq.com/',
               :email => 'support@datadoghq.com'
  ## end Company

  password :api_key
  string :tags

  # only include 'tags' in the debug logs, skip the api_key.
  white_list :tags

  default_events :push

  def receive_push
    # only handle pushes that include commits
    return unless payload['commits']

    api_key = required_config_value('api_key')
    tags = config_value('tags')

    post_event = format_event(payload)

    # Tags are optional
    post_event['tags'] = tags.split(',').map(&:strip) unless tags.nil?

    http_post datadog_event_endpoint do |req|
      req.params[:api_key] = api_key
      req.body = generate_json(post_event)
    end
  end

  private

  def datadog_event_endpoint
    'https://app.datadoghq.com/api/v1/events'
  end

  def format_event(payload)
    # Parse out some interesting info from the payload
    branch_name   = payload['ref'].split('/')[-1]
    repo_name     = payload['repository']['url'].split('/')[-2..-1].join('/')
    latest_commit = payload['commits'][-1]

    event_title = "#{payload['pusher']['name']} pushed to #{branch_name} at #{repo_name}"

    event_text = "There were #{payload['commits'].count} commits in this push.
      Compare URL: #{payload['compare']}
      Latest Commit by #{latest_commit['author']['name']}:
      #{latest_commit['id'][0..7]} #{latest_commit['message']}"

    post_event = {
      'date_happened' => Time.now.to_i, # The time the push happened.
      'priority' => 'normal',
      'source_type_name' => 'github',
      'text' => event_text,
      'title' => event_title
    }
    post_event
  end
end
