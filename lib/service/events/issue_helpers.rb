module Service::IssueHelpers
  include Service::HelpersWithMeta,
    Service::HelpersWithActions

  def issue
    @issue ||= self.class.objectify(payload['issue'])
  end

  def summary_url
    issue.html_url
  end

  def summary_message
    "[%s] %s %s issue #%d: %s" % [
      repo.name,
      sender.login,
      action,
      issue.number,
      issue.title]
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def self.sample_payload
    Service::HelpersWithMeta.sample_payload.merge(
      "action" => "opened",
      "issue" => {
        "number" => 5,
        "state" => "open",
        "title" => "booya",
        "body"  => "boom town",
        "user" => { "login" => "mojombo" }
      }
    )
  end
end
