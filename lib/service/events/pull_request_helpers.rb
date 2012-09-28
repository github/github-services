module Service::PullRequestHelpers
  include Service::HelpersWithMeta,
    Service::HelpersWithActions

  def pull
    @pull ||= self.class.objectify(payload['pull_request'])
  end

  def summary_url
    pull.html_url
  end

  def summary_message
    base_ref = pull.base.label.split(':').last
    head_ref = pull.head.label.split(':').last

    "[%s] %s %s pull request #%d: %s (%s...%s)" % [
      repo.name,
      sender.login,
      action,
      pull.number,
      pull.title,
      base_ref,
      head_ref != base_ref ? head_ref : pull.head.label]
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def self.sample_payload
    repo_owner = "mojombo"
    repo_name = "magik"
    pull_user = "foo"
    pull_number = 5
    Service::HelpersWithMeta.sample_payload.merge(
      "action" => "opened",
      "pull_request" => {
        "number" => pull_number,
        "commits" => 1,
        "state" => "open",
        "title" => "booya",
        "body"  => "boom town",
        "user" => { "login" => "#{pull_user}" },
        "head" => {"label" => "#{pull_user}:feature"},
        "base" => {"label" => "#{repo_owner}:master"},
        "html_url" => "https://github.com/#{repo_owner}/#{repo_name}/pulls/#{pull_number}"
      }
    )
  end
end

