require File.expand_path('../helper', __FILE__)

class HubCITest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_token_from_data
    assert_equal "5373dd4a3648b88fa9acb8e46ebc188a", @svc.token
  end

  def test_constructs_post_receive_url
    assert_equal 'https://node.ci/repository/mojombo/grit/onCommit/5373dd4a3648b88fa9acb8e46ebc188a',
      @svc.hubci_url
  end

  def test_strips_whitespace_from_form_values
    data = {
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a  '
    }

    svc = service(data, payload)
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.token
  end

  def test_pull_request_payload
    @svc = service(data, payload)
    @stubs.post '/repository/mojombo/grit/onCommit/5373dd4a3648b88fa9acb8e46ebc188a' do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal payload['commits'], JSON.parse(env[:body])['commits']
    end
    @svc.receive_push
  end

  def service(*args)
    super Service::NodeCI, *args
  end

  def data
    {
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a'
    }
  end

  def payload

    {
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
        },
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "clean up heads test",
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

