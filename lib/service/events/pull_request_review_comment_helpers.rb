module Service::PullRequestReviewCommentHelpers
  include Service::HelpersWithMeta

  def comment
    @comment ||= self.class.objectify(payload['comment'])
  end

  def summary_url
    comment.html_url
  end

  def pull_request_number
    comment.pull_request_url =~ /\/(\d+)$/
    $1
  end

  def summary_message
    "[%s] %s comment on pull request #%d %s: %s. %s" % [
      repo.name,
      sender.login,
      pull_request_number,
      comment.commit_id,
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
    commit_id   = "03af7b9daa89ea2821116adaabf78620a14346a0"

    Service::HelpersWithMeta.sample_payload.merge(
      "comment" => {
        "url" => "https://api.github.com/repos/#{repo_owner}/#{repo_name}/pulls/comments/#{comment_id}",
        "id" => comment_id,
        "user" => { "login" => "defunkt", },
        "body" => "very\r\ncool",
        "commit_id" => commit_id,
        "original_commit_id" => commit_id,
        "html_url" => "https://github.com/#{repo_owner}/#{repo_name}/pull/#{pull_number}#discussion_r#{comment_id}",
        "pull_request_url" => "https://api.github.com/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}",
        "_links" => {
          "self" => {
            "href" => "https://api.github.com/repos/#{repo_owner}/#{repo_name}/pulls/comments/#{comment_id}"
          },
          "html" => {
            "href" => "https://github.com/#{repo_owner}/#{repo_name}/pull/#{pull_number}#discussion_r#{comment_id}"
          },
          "pull_request" => {
            "href" => "https://api.github.com/#{repo_owner}/#{repo_name}/test/pulls/#{pull_number}"
          }
        }
      }
    )
  end
end
