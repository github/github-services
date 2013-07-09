module Service::IssueCommentHelpers
  include Service::HelpersWithMeta,
    Service::HelpersWithActions

  def issue
    @issue ||= self.class.objectify(payload['issue'])
  end

  def comment
    @comment ||= self.class.objectify(payload['comment'])
  end

  def summary_url
    comment.html_url
  end

  def summary_message
    "[%s] %s comment on issue #%d: %s. %s" % [
      repo.name,
      sender.login,
      issue.number,
      comment.body,
      comment.html_url
    ]
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def self.sample_payload
    Service::HelpersWithMeta.sample_payload.merge(
      "action" => "created",
      "issue" => {
        "number" => 5,
        "state" => "open",
        "title" => "booya",
        "body"  => "boom town",
        "user" => { "login" => "mojombo" }
      },
      "comment" => {
        "user" => { "login" => "defunkt" },
        "body" => "this\r\nis\r\ntest comment"
      }
    )
  end
end
