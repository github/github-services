# coding: utf-8
class Service::Talker < Service
  string  :url
  password :token
  boolean :digest
  white_list :url

  def receive_push
    repository = payload['repository']['name']
    branch     = branch_name
    commits    = payload['commits']

    prepare_http

    say "#{summary_message} – #{summary_url}"
    if data['digest'].to_i == 0
      if distinct_commits.size == 1
        commit = distinct_commits.first
        say format_commit_message(commit)
      else
        distinct_commits.each do |commit|
          say "#{format_commit_message(commit)} – #{commit['url']}"
        end
      end
    end
  end

  def receive_pull_request
    return unless opened?

    prepare_http
    say "#{summary_message}. #{summary_url}"
  end

  def receive_issues
    return unless opened?

    prepare_http
    say summary_message
  end

  private
    def prepare_http
      http.ssl[:verify] = false
      http.headers["X-Talker-Token"] = data['token']
      http.url_prefix = data['url']
    end

    def say(message)
      http_post 'messages.json', :message => message
    end
end
