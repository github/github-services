service :continuity_app do |data, payload|
  hook_url = URI.parse("http://hooks.continuityapp.com/github_selfservice/v1/%d" % data['project_id'].to_i)
  Net::HTTP.post_form(hook_url, :payload => JSON.generate(payload))
end