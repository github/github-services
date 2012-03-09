class Service::Pachube < Service
  string :api_key
  string :feed_id
  string :track_branch

  def receive_push
    raise_config_error "Missing api_key" if data['api_key'].to_s.empty?
    raise_config_error "Missing feed_id" if data['feed_id'].to_s.empty?

    feed_url = "https://api.pachube.com/v2/feeds/#{data['feed_id']}"

    if payload['ref'] == "refs/head/#{data[:track_branch]}" then
      http_method :put, "#{feed_url}/#{data['feed_id']}.json" do |req|
        req.headers['X-PachubeApiKey'] = data['api_key']
        req.body = {
          :version => '1.0.0',
          :datastreams => [
            {
              :id => "#{repo_name}.commits_pushed",
              :current_value => distinct_commits.size
            },
            {
              :id => "#{repo_name}.modified"
            },
            {
              :id => "#{repo_name}.removed"
            },
            {
              :id => "#{repo_name}.added"
            }
          ]}.to_json
      end
      distinct_commits.each do |commit|
        [ 'modified', 'removed', 'added' ].each do |ds|
          http_method :post, "#{feed_url}/datastreams/#{repo_name}.#{ds}/datapoints.json" do |req|
            req.headers['X-PachubeApiKey'] = data['api_key']
            req.body = {
              :version => '1.0.0',
              :datapoints => [
                {
                  :at => commit['timestamp'],
                  :value => commit[ds].size
                }
              ]}.to_json
          end
        end
      end
    end
  end
end
