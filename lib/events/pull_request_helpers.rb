module Service::PullRequestHelpers
  include Service::HelpersWithRepo,
    Service::HelpersWithActions

  def pull
    @pull ||= self.class.objectify(payload['pull_request'])
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

