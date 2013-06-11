require File.expand_path('../helper', __FILE__)

class PackagistTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_user_from_data
    assert_equal 'simensen', @svc.user
  end

  def test_reads_token_from_data
    assert_equal "5gieo7lwcd8gww800scs", @svc.token
  end

  def test_reads_domain_from_data
    assert_equal "packagist.example.com", @svc.domain
  end

  def test_keeps_https_scheme
    svc = service(data.merge({'domain' => 'https://example.com'}), payload)
    assert_equal 'https', svc.scheme
  end

  def test_constructs_post_receive_url
    assert_equal 'http://packagist.example.com/api/github',
      @svc.packagist_url
  end

  def test_posts_payload
    @stubs.post '/api/github' do |env|
      assert_equal 'packagist.example.com', env[:url].host
      assert_equal 'simensen', Faraday::Utils.parse_query(env[:body])['username']
      assert_equal '5gieo7lwcd8gww800scs', Faraday::Utils.parse_query(env[:body])['apiToken']
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end
    @svc.receive_push
  end

  def test_strips_whitespace_from_form_values
    data = {
      'user' => 'simensen  ',
      'token' => '5gieo7lwcd8gww800scs  ',
      'domain' => 'packagist.example.com   '
    }

    svc = service(data, payload)
    assert_equal 'simensen', svc.user
    assert_equal '5gieo7lwcd8gww800scs', svc.token
    assert_equal 'packagist.example.com', svc.domain
  end

  def test_handles_blank_strings_without_errors
    data = {
      'user' => '',
      'token' => '5gieo7lwcd8gww800scs',
      'domain' => ''
    }

    svc = service(data, payload)
    assert_equal 'mojombo', svc.user
    assert_equal '5gieo7lwcd8gww800scs', svc.token
    assert_equal 'packagist.org', svc.domain
    assert_equal 'http', svc.scheme
  end

  def test_detects_http_url
    data = {
      'domain' => 'http://packagist.example.com/'
    }

    svc = service(data, payload)
    assert_equal 'packagist.example.com', svc.domain
    assert_equal 'http', svc.scheme
  end

  def test_detects_https_url
    data = {
      'domain' => 'https://packagist.example.com/'
    }

    svc = service(data, payload)
    assert_equal 'packagist.example.com', svc.domain
    assert_equal 'https', svc.scheme
  end

  def test_strips_trailing_slash
    data = {
      'domain' => 'packagist.example.com/   '
    }

    svc = service(data, payload)
    assert_equal 'packagist.example.com', svc.domain
  end

  def test_strips_trailing_slash_deep_path
    data = {
      'domain' => 'packagist.example.com/path/to/subdirectory/  '
    }

    svc = service(data, payload)
    assert_equal 'packagist.example.com/path/to/subdirectory', svc.domain
  end

  def test_infers_user_from_repo_data
    svc = service(data.reject{|key,v| key == 'user'}, payload)
    assert_equal "mojombo", svc.user
  end

  def test_defaults_to_http_scheme
    assert_equal 'http', @svc.scheme
  end

  def test_defaults_to_packagist_domain
    svc = service(data.reject{|key,v| key == 'domain'}, payload)
    assert_equal "packagist.org", svc.domain
  end

  def service(*args)
    super Service::Packagist, *args
  end

  def data
    {
      'user' => 'simensen',
      'token' => '5gieo7lwcd8gww800scs',
      'domain' => 'packagist.example.com'
    }
  end
  def payload2
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

