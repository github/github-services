require File.expand_path('../helper', __FILE__)
require 'rack/test'

class ServiceAppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  class TestAppService < Service
    class << self
      attr_accessor :tested
    end

    def receive_booya
      self.class.tested << self
    end
  end

  def setup
    TestAppService.tested = []
  end

  def test_http_post
    data = {'a' => 1}
    payload = {'b' => 2}
    post "/testappservice/booya",
      :data => JSON.generate(data),
      :payload => JSON.generate(payload)
    assert_equal 200, last_response.status

    assert svc = TestAppService.tested.shift
    assert_nil TestAppService.tested.first

    assert_equal data, svc.data
    assert_equal payload, svc.payload
    assert_equal :booya, svc.event
    assert_nil svc.meta
  end

  def test_json_post
    data = {'a' => 1}
    payload = {'b' => 2}
    meta = {
      :id => 123,
      :sender => {:id => 10, :login => 'sender', :gravatar_id => 'aaa'},
      :repository => {:id => 20, :source_id => 30, :name => 'octocat'},
      :user => {:id => 40, :login => 'github', :gravatar_id => 'bbb'}
    }

    header 'Content-Type', Service::App::JSON_TYPE
    post "/testappservice/booya", {},
      :input => JSON.generate(:meta => meta, :data => data, :payload => payload)

    assert_equal 200, last_response.status

    assert svc = TestAppService.tested.shift
    assert_nil TestAppService.tested.first

    assert_equal data, svc.data
    assert_equal payload, svc.payload
    assert_equal :booya, svc.event

    assert_equal meta[:id], svc.meta.id
    assert_equal meta[:sender][:id], svc.meta.sender.id
    assert_equal meta[:sender][:login], svc.meta.sender.login

    assert_equal meta[:repository][:id], svc.meta.repository.id
    assert_equal meta[:repository][:name], svc.meta.repository.name
    assert_equal meta[:user][:id], svc.meta.repository.owner.id
    assert_equal meta[:user][:login], svc.meta.repository.owner.login

    assert_equal "https://github.com/github", svc.meta.repository.owner.url
    assert_equal "https://github.com/github/octocat", svc.meta.repository.url
  end

  def test_nagios_check
    get '/'
    assert_equal 'ok', last_response.body
  end

  def app
    Service::App
  end
end
