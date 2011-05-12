service :yammer do |data, payload|
  statuses   = [ ]
  repository = payload['repository']['name']

  if data['digest'] == '1'
    commit = payload['commits'][-1]
    tiny_url = shorten_url(payload['repository']['url'] + '/commits/' + payload['ref_name'])
    statuses << "@#{commit['author']['name']} pushed #{payload['commits'].length}.  #{tiny_url} \##{repository}"
  else
    payload['commits'].each do |commit|
      tiny_url = shorten_url(commit['url'])
      statuses << "#{commit['message']} (committer: @#{commit['author']['name']}) #{tiny_url} \##{repository}"
    end
  end


  yammer = Yammer::Client.new(:consumer =>
                                {:key => data['consumer_key'],
                                 :secret => data['consumer_secret']},
                              :access =>
                                {:token => data['access_token'],
                                 :secret => data['access_secret']})

  statuses.each do |status|
    params = { :body => status }
    params['group_id'] = data['group_id'] unless data['group_id'].to_s.empty?
    yammer.message(:post, params)
  end
end
