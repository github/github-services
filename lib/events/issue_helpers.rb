module Service::IssueHelpers
  include Service::HelpersWithRepo,
    Service::HelpersWithActions

  def issue
    @issue ||= self.class.objectify(payload['issue'])
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
