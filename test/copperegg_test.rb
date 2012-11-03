require File.expand_path('../helper', __FILE__)

class CopperEggTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data = {
      'url'         => 'https://api.copperegg.com/custom',
      'api_key'     => '134567890',
      'tag'         => 'newtag',
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

    @stubs.post "/custom" do |env|
      assert_match "Basic MTM0NTY3ODkwOlU=", env[:request_headers]["authorization"]
      assert_equal "application/json", env[:request_headers]["Content-Type"]
      assert_match "GitHub: rtomayko has pushed 1 commit(s) to grit", env[:body]
      assert_match "newtag", env[:body]
      [200, {}, '']
    end
    svc.receive_push
  end

  def service(*args)
    super Service::CopperEgg, *args
  end
end
