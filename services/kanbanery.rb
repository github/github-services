secrets = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'secrets.yml'))
site = "http://kanbanery.com/api/v1/projects"
action = "git_commits"
service :kanbanery do |data, payload|
  project_id = secrets['kanbanery']['project_id']
  commits   = [ ]
  repository = payload['repository']['name']

  if data['digest'] == '1'
    commit = payload['commits'][-1]
    commit_info = {
      :tiny_url => shorten_url(payload['repository']['url'] + '/commits/' + payload['ref_name']),
      :message  => commit['message'] #???
    }
    commits << commit_info
  else
    payload['commits'].each do |commit|
      commit_info = {
        :tiny_url => shorten_url(commit['url']),
        :message  => commit['message'],
        :author   => commit['author']['name'] || commit['author']['email'],
        :ref      => commit['ref']
      }
      commits << commit_info
    end
  end

  #send commits to "#{site}/#{project_id}/#{action}"

  
end