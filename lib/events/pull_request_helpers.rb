module Service::PullRequestHelpers
  def action
    payload['action'].to_s
  end

  def opened?
    action == 'opened'
  end

  def pull
    @pull ||= self.class.objectify(payload['pull_request'])
  end

  def repo
    @repo ||= self.class.objectify(payload['repository'])
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

