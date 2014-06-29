require 'test/unit'
require 'pp'
require File.expand_path('../../config/load', __FILE__)
Service.load_services

class Service::TestCase < Test::Unit::TestCase
  ALL_SERVICES = Service.services.dup

  def test_default
  end

  def service(klass, event_or_data, data, payload=nil)
    event = nil
    if event_or_data.is_a?(Symbol)
      event = event_or_data
    else
      payload = data
      data    = event_or_data
      event   = :push
    end

    service = klass.new(event, data, payload)
    service.http :adapter => [:test, @stubs]
    service.delivery_guid = "guid-#{rand}"
    service
  end

  def basic_auth(user, pass)
    "Basic " + ["#{user}:#{pass}"].pack("m*").strip
  end

  def push_payload
    Service::PushHelpers.sample_payload
  end
  alias payload push_payload

  def pull_payload
    Service::PullRequestHelpers.sample_payload
  end

  def pull_request_review_comment_payload
    Service::PullRequestReviewCommentHelpers.sample_payload
  end

  def issues_payload
    Service::IssueHelpers.sample_payload
  end

  def issue_comment_payload
    Service::IssueCommentHelpers.sample_payload
  end

  def commit_comment_payload
    Service::CommitCommentHelpers.sample_payload
  end

  def public_payload
    Service::PublicHelpers.sample_payload
  end

  def gollum_payload
    Service::GollumHelpers.sample_payload
  end

  def basic_payload
    Service::HelpersWithMeta.sample_payload
  end

  def deployment_payload
    Service::DeploymentHelpers.sample_deployment_payload
  end
end

module Service::HttpTestMethods
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end


  def service(event_or_data, data, payload = nil)
    super(service_class, event_or_data, data, payload)
  end

  def service_class
    raise NotImplementedError
  end
end

