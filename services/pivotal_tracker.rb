class Service::PivotalTracker < Service
  string :token, :branch

  def receive_push
    token = data['token']
    branch = data['branch'].to_s
    ref = payload["ref"].to_s

    # need to figure out how to get the right equifax secure ca loaded
    http.ssl[:verify] = false

    if branch.empty? || branch == ref.split("/").last
      notifier.call
    end
  end

  attr_writer :notifier

  def notifier
    @notifier ||= Proc.new { notify }
  end

  private
  def notify
    res = http_post 'https://www.pivotaltracker.com/services/v3/github_commits' do |req|
      req.params[:token] = data['token']
      req.body = {:payload => payload.to_json}
    end

    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end

