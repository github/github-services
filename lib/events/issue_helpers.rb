module Service::IssueHelpers
  def action
    payload['action'].to_s
  end

  def opened?
    action == 'opened'
  end

  def issue
    @issue ||= self.class.objectify(payload['issue'])
  end

  def repo
    @repo ||= self.class.objectify(payload['repository'])
  end

  def self.sample_payload
    {
      "action" => "opened",
      "issue" => {
        "number" => 5,
        "state" => "open",
        "title" => "booya",
        "body"  => "boom town",
        "user" => { "login" => "mojombo" }
      },
      "repository" => {
        "name"  => "grit",
        "url"   => "http://github.com/mojombo/grit",
        "owner" => { "login" => "mojombo" }
      }
    }
  end
end
