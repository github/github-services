class Service::Yammer < Service
  string :group_id, :consumer_key, :consumer_secret,
    :access_token, :access_secret
  boolean :digest, :master_only
  white_list :group_id, :master_only

  def receive_push
    return if data['master_only'].to_i == 1 && respond_to?(:branch_name) && branch_name != 'master'

    statuses   = [ ]
    repository = payload['repository']['name']

    if data['digest'] == '1'
      commit   = payload['commits'][-1]
      tiny_url = shorten_url("#{payload['repository']['url']}/commits/#{ref_name}")
      statuses << "#{commit['author']['name']} pushed #{payload['commits'].length}.  #{tiny_url} \##{repository}"
    else
      payload['commits'].each do |commit|
        tiny_url = shorten_url(commit['url'])
        statuses << "#{commit['message']} (committer: #{commit['author']['name']}) #{tiny_url} \##{repository}"
      end
    end

    statuses.each do |status|
      params = { :body => status }
      params['group_id'] = data['group_id'] unless data['group_id'].to_s.empty?
      begin
        send_message params
      rescue
        if $!.to_s =~ /authentication failed/i
          raise_config_error "Invalid username or password"
        else
          raise
        end
      end
    end
  end

  def send_message(params)
    yammer.message(:post, params)
  rescue RuntimeError => boom
    if boom.to_s =~ /Bad Request/i
      raise_config_error boom.to_s
    else
      raise
    end
  end

  def yammer
    @yammer ||= ::Yammer::Client.new \
      :consumer => {
        :key    => data['consumer_key'],
        :secret => data['consumer_secret']},
      :access => {
        :token  => data['access_token'],
        :secret => data['access_secret']}
  end
end

