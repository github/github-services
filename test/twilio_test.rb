require File.expand_path('../helper', __FILE__)

module Twilio
  module REST
    class Client
      def connect_and_send(request)
        {
        "account_sid" => "account_sid",
        "api_version" => "2010-04-01",
        "body" => "rtomayko has pushed 1 commit(s) to grit",
        "date_created" => "Wed, 23 Oct 2011 20 =>01 =>40 +0000",
        "date_sent" => nil,
        "date_updated" => "Wed, 18 Aug 2010 20 =>01 =>40 +0000",
        "direction" => "outbound-api",
        "from" => "+12223334444",
        "price" => nil,
        "sid" => "SM90c6fc909d8504d45ecdb3a3d5b3556e",
        "status" => "queued",
        "to" => "+15556667777",
        "uri" => "/2010-04-01/Accounts/account_sid/SMS/Messages.json"
        }
      end
    end
  end
end

class TwilioTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data = {
      'account_sid' => 'account_sid',
      'auth_token' => 'auth_token',
      'from_phone' => '+12223334444',
      'to_phone' => '+15556667777',
      'master_only' => '0'
    }
    @payload = {
      "after"   => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "ref"     => "refs/heads/master",
      "before"  => "4c8124ffcf4039d292442eeccabdeca5af5c5017",
      "compare" => "http://github.com/mojombo/grit/compare/4c8124ffcf4039d292442eeccabdeca5af5c5017...a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "forced"  => false,
      "created" => false,
      "deleted" => false,

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
          "message"   => "[#WEB-249 status:31 resolution:1] stub git call for Grit#heads test",
          "added"     => [],
          "timestamp" => "2007-10-10T00:11:02-07:00",
          "modified"  => ["lib/grit/grit.rb", "test/helper.rb", "test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "06f63b43050935962f84fe54473a7c5de7977325"
        }
      ]
    }
  end

  def test_push
    svc = service(@data, @payload)
    assert_equal 1, @payload['commits'].size
    assert_equal 'rtomayko', @payload['pusher']['name']
    assert_equal 'grit', @payload['repository']['name']

    @stubs.post "/2010-04-01/Accounts/account_sid/SMS/Messages.json" do |env|
      [200, {}, '']
    end

    twilio_response = svc.receive_push
    assert twilio_response.is_a?(Twilio::REST::Message)
    assert_equal 'rtomayko has pushed 1 commit(s) to grit', twilio_response.body
  end

  def test_push_master_only_on_non_master
    non_master_payload = @payload
    non_master_payload["ref"] = "refs/heads/non-master"

    data_with_master_only = @data
    data_with_master_only['master_only'] = 1

    svc = service(data_with_master_only, non_master_payload)
    twilio_response = svc.receive_push
    assert_equal twilio_response, nil
  end

  def test_push_master_only_on_master
    data_with_master_only = @data
    data_with_master_only['master_only'] = 1

    @stubs.post "/2010-04-01/Accounts/account_sid/SMS/Messages.json" do |env|
      [200, {}, '']
    end

    svc = service(data_with_master_only, @payload)
    twilio_response = svc.receive_push
    assert twilio_response.is_a?(Twilio::REST::Message)
    assert_equal 'rtomayko has pushed 1 commit(s) to grit', twilio_response.body
  end

  def service(*args)
    super Service::Twilio, *args
  end
end

