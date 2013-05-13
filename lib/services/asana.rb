class Service::Asana < Service
  string :auth_token, :restrict_to_branch
  boolean :restrict_to_last_commit
  white_list :restrict_to_branch, :restrict_to_last_comment

  def receive_push
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''

    user = payload['pusher']['name']
    branch = payload['ref'].split('/').last

    branch_restriction = data['restrict_to_branch'].to_s
    commit_restriction = data['restrict_to_last_comment'] == "1"

    # check the branch restriction is poplulated and branch is not included
    if branch_restriction.length > 0 && branch_restriction.index(branch) == nil
      return
    end

    rep = payload['repository']['url'].split('/').last(2).join('/')
    push_msg = user + " pushed to branch " + branch + " of " + rep

    # code heavily derived from fog_bugz.rb
    # iterate over commits
    if commit_restriction
      check_commit( payload['commits'].last, push_msg )
    else
      payload['commits'].each do |commit|
        check_commit( commit, push_msg )
      end
    end
  end

  def check_commit(commit, push_msg)
    message = " (" + commit['url'] + ")\n- " + commit['message']

    task_list = []
    message.split("\n").each do |line|
      task_list.concat( line.scan(/#(\d+)/) )
      task_list.concat( line.scan(/https:\/\/app\.asana\.com\/\d+\/\d+\/(\d+)/) )
    end

    # post commit to every taskid found
    task_list.each do |taskid|

      http.basic_auth(data['auth_token'], "")
      http.headers['X-GitHub-Event'] = event.to_s

      res = http_post "https://app.asana.com/api/1.0/tasks/" + taskid[0] + "/stories", "text=" + push_msg + message
      if res.status < 200 || res.status > 299
        raise_config_error res.message
      end
    end
  end

end
