class Service::Asana < Service
  string :auth_token

  def receive_push
    # make sure we have what we need
    raise_config_error "Missing 'auth_token'" if data['auth_token'].to_s == ''

    user = payload['pusher']['name']
    branch = payload['ref'].split('/').last
    # rep = payload['repository']['name'] + "/" + payload['name']
    rep = payload['repository']['url'].split('/').last(2).join('/')
    push_msg = user + " pushed to branch " + branch + " of " + rep

    # code heavily derived from fog_bugz.rb
    # iterate over commits
    payload['commits'].each do |commit|
      message = " (" + commit['url'] + ")\n- " + commit['message']

      task_list = []
      message.split("\n").each do |line|
        task_list.concat( line.scan(/#(\d+)/) )
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
end
