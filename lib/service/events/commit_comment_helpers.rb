module Service::CommitCommentHelpers
  include Service::HelpersWithMeta

  def comment
    @comment ||= self.class.objectify(payload['comment'])
  end

  def summary_url
    comment.html_url
  end

  def summary_message
    "[%s] %s comment on commit %s: %s. %s" % [
      repo.name,
      sender.login,
      comment.commit_id,
      comment.body,
      comment.html_url
    ]
  rescue
    raise_config_error "Unable to build message: #{$!.to_s}"
  end

  def self.sample_payload
    comment_id = 3332777
    commit_id  = "441e5686a726b79bcdace639e2591a60718c9719"
    Service::HelpersWithMeta.sample_payload.merge(
      "comment" => {
        "user" => { "login" => "defunkt" },
        "commit_id" => commit_id,
        "body" => "this\r\nis\r\ntest comment",
        "html_url" => "https://github.com/mojombo/magik/commit/#{commit_id}#commitcomment-#{comment_id}"
      }
    )
  end
end
