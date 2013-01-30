# This is a set of common helpers for Push events.
module Service::PushHelpers
  def created?
    payload['created'] || !!(payload['before'] =~ /0{40}/)
  end

  def deleted?
    payload['deleted'] || !!(payload['after'] =~ /0{40}/)
  end

  def forced?
    payload['forced']
  end

  def ref
    payload['ref'].to_s
  end

  def base_ref
    payload['base_ref']
  end

  def tag?
    !!(ref =~ %r|^refs/tags/|)
  end

  def ref_name
    payload['ref_name'] ||= ref.sub(/\Arefs\/(heads|tags)\//, '')
  end
  alias :tag_name :ref_name
  alias :branch_name :ref_name

  def base_ref_name
    payload['base_ref_name'] ||= base_ref.sub(/\Arefs\/(heads|tags)\//, '')
  end

  def before_sha
    payload['before'][0..6]
  end

  def after_sha
    payload['after'][0..6]
  end

  def format_commit_message(commit)
    short = commit['message'].split("\n", 2).first
    "[#{repo_name}/#{branch_name}] #{short} - #{commit['author']['name']}"
  end

  def commit_messages
    distinct_commits.map do |commit|
      format_commit_message(commit)
    end
  end

  def summary_message
    message = []
    message << "[#{repo_name}] #{pusher_name}"

    if created?
      if tag?
        message << "tagged #{tag_name} at"
        message << (base_ref ? base_ref_name : after_sha)
      else
        message << "created #{branch_name}"

        if base_ref
          message << "from #{base_ref_name}"
        elsif distinct_commits.empty?
          message << "at #{after_sha}"
        end

        if distinct_commits.any?
          num = distinct_commits.size
          message << "(+#{num} new commit#{num > 1 ? 's' : ''})"
        end
      end

    elsif deleted?
      message << "deleted #{branch_name} at #{before_sha}"

    elsif forced?
      message << "force-pushed #{branch_name} from #{before_sha} to #{after_sha}"

    elsif commits.any? and distinct_commits.empty?
      if base_ref
        message << "merged #{base_ref_name} into #{branch_name}"
      else
        message << "fast-forwarded #{branch_name} from #{before_sha} to #{after_sha}"
      end

    elsif distinct_commits.any?
      num = distinct_commits.size
      message << "pushed #{num} new commit#{num > 1 ? 's' : ''} to #{branch_name}"

    else
      message << "pushed nothing"
    end

    message.join(' ')
  end

  def summary_url
    if created?
      if distinct_commits.empty?
        branch_url
      else
        compare_url
      end

    elsif deleted?
      before_sha_url

    elsif forced?
      branch_url

    elsif distinct_commits.size == 1
      distinct_commits.first['url']

    else
      compare_url
    end
  end

  def repo_url
    payload['repository']['url']
  end

  def compare_url
    payload['compare']
  end

  def branch_url
    repo_url + "/commits/#{branch_name}"
  end

  def before_sha_url
    repo_url + "/commit/#{before_sha}"
  end

  def after_sha_url
    repo_url + "/commit/#{after_sha}"
  end

  def pusher_name
    payload.include?('pusher') ? payload['pusher']['name'] : "somebody"
  end

  def owner_name
    payload['repository']['owner']['name']
  end

  def repo_name
    payload['repository']['name']
  end

  def name_with_owner
    File.join(owner_name, repo_name)
  end

  def commits
    Array(payload['commits'])
  end

  def distinct_commits
    payload['distinct_commits'] ||= Array(commits.select do |commit|
      commit['distinct'] and !commit['message'].to_s.strip.empty?
    end)
  end

  def self.sample_payload
    {
      "after"  => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "ref"    => "refs/heads/master",
      "before" => "4c8124ffcf4039d292442eeccabdeca5af5c5017",
      "compare" => "http://github.com/mojombo/grit/compare/4c8124f...a47fd41",

      "repository" => {
        "name"  => "grit",
        "url"   => "http://github.com/mojombo/grit",
        "owner" => { "name" => "mojombo", "email" => "tom@mojombo.com" }
      },

      "pusher" => {
        "name" => "rtomayko"
      },

      "commits" => [
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "stub git call for Grit#heads test f:15 Case#1",
          "added"     => [],
          "timestamp" => "2007-10-10T00:11:02-07:00",
          "modified"  => ["lib/grit/grit.rb", "test/helper.rb", "test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "06f63b43050935962f84fe54473a7c5de7977325"
        },
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "clean up heads test f:2hrs",
          "added"     => [],
          "timestamp" => "2007-10-10T00:18:20-07:00",
          "modified"  => ["test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/5057e76a11abd02e83b7d3d3171c4b68d9c88480",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "5057e76a11abd02e83b7d3d3171c4b68d9c88480"
        },
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "add more comments throughout",
          "added"     => [],
          "timestamp" => "2007-10-10T00:50:39-07:00",
          "modified"  => ["lib/grit.rb", "lib/grit/commit.rb", "lib/grit/grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425"
        }
      ]
    }
  end
end
