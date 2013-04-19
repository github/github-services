class Service::Pachube < Service
  string :api_key, :feed_id, :track_branch
  white_list :feed_id, :track_branch

  def receive_push
    raise_config_error "Missing api_key" if data['api_key'].to_s.empty?
    raise_config_error "Missing feed_id" if data['feed_id'].to_s.empty?
    raise_config_error "Missing track_branch" if data['track_branch'].to_s.empty?

    feed_url = "https://api.pachube.com/v2/feeds/#{data['feed_id']}"

    if payload['ref'] == "refs/heads/#{data['track_branch']}" then
      http_method :put, "#{feed_url}.json" do |req|
        req.headers['X-PachubeApiKey'] = data['api_key']
        req.body = generate_json(
          :version => '1.0.0',
          :datastreams => [
            {
              :id => "#{repo_name}-commits_pushed",
              :current_value => distinct_commits.size
            },
            {
              :id => "#{repo_name}-files_modified"
            },
            {
              :id => "#{repo_name}-files_removed"
            },
            {
              :id => "#{repo_name}-files_added"
            }
          ])
      end
      distinct_commits.each do |commit|
        [ 'modified', 'removed', 'added' ].each do |ds|
          http_method :post, "#{feed_url}/datastreams/#{repo_name}-files_#{ds}/datapoints" do |req|
            req.headers['X-PachubeApiKey'] = data['api_key']
            req.body = generate_json(
              :version => '1.0.0',
              :datapoints => [
                {
                  :at => commit['timestamp'],
                  :value => commit[ds].size
                }
              ])
          end
        end
      end
    end
  end
end
