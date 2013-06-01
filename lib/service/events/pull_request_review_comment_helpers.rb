module Service::PullRequestReviewCommentHelpers
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
    "[%s] %s %s comment pull request #%d: %s. %s" % [
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
    repo_owner  = "mojombo"
    repo_name   = "magik"
    pull_user   = "foo"
    pull_number = 5
    comment_id  = 18785396
    Service::HelpersWithMeta.sample_payload.merge(
      "action" => "created",
      "issue" => {
        "html_url" => "https://github.com/#{repo_owner}/#{repo_name}/issues/#{pull_number}",
        "id" => 15024387,
        "number" => pull_number,
        "title" => "booya",
        "user" => { "login" => "#{pull_user}", },
        "pull_request" => {
          "html_url" => "https://github.com/#{repo_owner}/#{repo_name}/pull/#{pull_number}",
          "diff_url" => "https://github.com/#{repo_owner}/#{repo_name}/pull/#{pull_number}.diff",
          "patch_url" => "https://github.com/#{repo_owner}/#{repo_name}/pull/#{pull_number}.patch"
        },
        "body" => "boom town"
      },
      "comment" => {
        "html_url" => "https://github.com/#{repo_owner}/#{repo_name}/issues/#{pull_number}#issuecomment-#{comment_id}",
        "id" => comment_id,
        "user" => { "login" => "defunkt", },
        "body" => "very\r\ncool"
      },
    )
  end
end
