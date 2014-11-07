class Service::Asana < Service
  password :auth_token
  string :restrict_to_branch
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
    message = "(#{commit['url']})\n- #{commit['message']}"

    task_list = []
    message.split("\n").each do |line|
      task_list.concat( line.scan(/#(\d+)/) )
      task_list.concat( line.scan(/https:\/\/app\.asana\.com\/\d+\/\d+\/(\d+)/) )
    end

    # post commit to every taskid found
    task_list.flatten.each do |taskid|
      deliver_story taskid, "#{push_msg} #{message}"
    end
  end

  def deliver_story(task_id, text)
    http.basic_auth(data['auth_token'], "")
    http.headers['X-GitHub-Event'] = event.to_s

    res = http_post "https://app.asana.com/api/1.0/tasks/#{task_id}/stories", "text=#{text}"
    case res.status
    when 200..299
      # Success
    when 400
      # Unknown task. Could be GitHub issue or pull request number. Ignore it.
    else
      # Try to pull out an error message from the Asana response
      error_message = JSON.parse(res.body)['errors'][0]['message'] rescue nil
      raise_config_error(error_message || "Unexpected Error")
    end
  end
end
