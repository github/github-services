require File.expand_path('../helper', __FILE__)

class NodejitsuTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_user_from_data
    assert_equal 'kronn', @svc.username
  end

  def test_reads_password_from_data
    assert_equal "5373dd4a3648b88fa9acb8e46ebc188a", @svc.password
  end

  def test_reads_domain_from_data
    assert_equal "webhooks.nodejitsu.com", @svc.domain
  end

  def test_reads_branch_from_data
    assert_equal "master", @svc.branch
  end

  def test_reads_email_errors_from_data
    assert_equal true, @svc.email_errors
  end

  def test_reads_email_success_deploys_from_data
    assert_equal false, @svc.email_success_deploys
  end

  def test_keeps_http_scheme
    svc = service(data.merge({'endpoint' => 'http://example.com'}), payload)
    assert_equal 'http', svc.scheme
  end

  def test_keeps_domain
    svc = service(data.merge({'endpoint' => 'http://example.com'}), payload)
    assert_equal 'example.com', svc.domain
  end

  def test_constructs_post_receive_url
    assert_equal 'https://webhooks.nodejitsu.com/1/deploy',
      @svc.nodejitsu_url
  end

  def test_posts_payload
    @stubs.post '/1/deploy' do |env|
      assert_equal 'webhooks.nodejitsu.com', env[:url].host
      assert_equal basic_auth('kronn', '5373dd4a3648b88fa9acb8e46ebc188a'),
        env[:request_headers]['authorization']
    end
    @svc.receive_push
  end

  def test_strips_whitespace_from_form_values
    data = {
      'username' => 'kronn  ',
      'password' => '5373dd4a3648b88fa9acb8e46ebc188a  ',
      'endpoint' => 'hooks.nodejitsu.com   ',
      'branch' => 'integration  '
    }

    svc = service(data, payload)
    assert_equal 'kronn', svc.username
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.password
    assert_equal 'hooks.nodejitsu.com', svc.domain
    assert_equal 'https', svc.scheme
    assert_equal 'integration', svc.branch
  end

  def test_handles_blank_strings_without_errors
    data = {
      'username' => '',
      'password' => '5373dd4a3648b88fa9acb8e46ebc188a',
      'domain' => '',
      'branch' => ''
    }

    svc = service(data, payload)
    assert_equal 'mojombo', svc.username
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.password
    assert_equal 'webhooks.nodejitsu.com', svc.domain
    assert_equal 'https', svc.scheme
    assert_equal 'master', svc.branch
  end

  def test_infers_user_from_repo_data
    svc = service(data.reject{|key,v| key == 'username'}, payload)
    assert_equal "mojombo", svc.username
  end

  def test_defaults_to_https_scheme
    assert_equal 'https', @svc.scheme
  end

  def test_defaults_to_nodejitsu_domain
    svc = service(data.reject{|key,v| key == 'domain'}, payload)
    assert_equal "webhooks.nodejitsu.com", svc.domain
  end

  def service(*args)
    super Service::Nodejitsu, *args
  end

  def data
    {
      'username'              => 'kronn',
      'password'              => '5373dd4a3648b88fa9acb8e46ebc188a',
      'domain'                => 'webhooks.nodejitsu.com',
      'branch'                => 'master',
      'email_success_deploys' => false,
      'email_errors'          => true
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

