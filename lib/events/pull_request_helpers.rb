module Service::PullRequestHelpers
  include Service::HelpersWithRepo,
    Service::HelpersWithActions

  def pull
    @pull ||= self.class.objectify(payload['pull_request'])
  end

  def summary_url
    pull.html_url
  end

  def summary_message
    "[%s] %s - %s. %s -> %s %s" % [
      repo.name,
      pull.title,
      pull.user.login,
      pull.base.label, pull.head.label,
      pull.html_url]
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def self.sample_payload
    {
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
      },
      "repository" => {
        "name"  => "grit",
        "url"   => "http://github.com/mojombo/grit",
        "owner" => { "login" => "mojombo" }
      }
    }
  end
end

