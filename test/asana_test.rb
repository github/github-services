require File.expand_path('../helper', __FILE__)

class AsanaTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push

    @stubs.post "/api/1.0/tasks/1234/stories" do |env|
      assert_match "rtomayko pushed to branch master of mojombo/grit", env[:body]
      assert_match /#1234/, env[:body]
      assert_match "Basic MDAwMDo=", env[:request_headers][:authorization]
      [200, {}, '']
    end

    @stubs.post "/api/1.0/tasks/1235/stories" do |env|
      assert_match "rtomayko pushed to branch master of mojombo/grit", env[:body]
      assert_match /#1235/, env[:body]
      assert_match "Basic MDAwMDo=", env[:request_headers][:authorization]
      [200, {}, '']
    end

    svc = service(
      {'auth_token' => '0000'},
      modified_payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Asana, *args
  end

  def modified_payload
    pay = payload
    pay['commits'][0]['message'] = "stub git call for Grit#heads test f:15 Case#1234"
    pay['commits'][1]['message'] = "#1234 clean up heads test f:2hrs"
    pay['commits'][2]['message'] = "add more comments about #1235 and #1234 throughout"
    pay
  end

 end