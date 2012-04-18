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

    "[%s] %s %s pull request #%d: %s (%s...%s) %s" % [
      repo.name,
      sender.login,
      action,
      pull.number,
      pull.title,
      base_ref,
      head_ref != base_ref ? head_ref : pull.head.label,
      pull.html_url]
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def self.sample_payload
    Service::HelpersWithMeta.sample_payload.merge(
      "action" => "opened",
      "pull_request" => {
        "number" => 5,
        "commits" => 1,
        "state" => "open",
        "title" => "booya",
        "body"  => "boom town",
        "user" => { "login" => "mojombo" },
        "head" => {"label" => "foo:feature"},
        "base" => {"label" => "mojombo:master"}
      }
    )
  end
end

