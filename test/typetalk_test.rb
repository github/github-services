require File.expand_path('../helper', __FILE__)

class TypetalkTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @stubs.post "/oauth2/access_token" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      assert_equal 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', form['client_id']
      assert_equal 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', form['client_secret']
      assert_equal 'client_credentials', form['grant_type']
      assert_equal 'topic.post', form['scope']
      [200, {}, '{ "access_token": "TestToken" }']
    end
  end

  def test_push
    @stubs.post "/api/v1/topics/1" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      headers = env[:request_headers]
      assert_equal 'Bearer TestToken', headers['Authorization']
      assert_equal "dragon3 has pushed 2 commit(s) to master at dragon3/github-services\nhttps://github.com/dragon3/github-services/compare/06f63b43050935962f84fe54473a7c5de7977325...06f63b43050935962f84fe54473a7c5de7977326", form['message']
      [200, {}, '']
    end

    svc = service(:push, {'client_id' => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                   'client_secret' => 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
                   'topic' => '1'}, payload_for_push_test)
    svc.receive_push
  end

  def test_pull_request
    @stubs.post "/api/v1/topics/1" do |env|
      form = Faraday::Utils.parse_query(env[:body])
      headers = env[:request_headers]
      assert_equal 'Bearer TestToken', headers['Authorization']
      assert_equal "defunkt opened pull request #5: booya\nhttps://github.com/mojombo/magik/pulls/5", form['message']
      [200, {}, '']
    end
    svc = service(:pull_request, {'client_id' => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                   'client_secret' => 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
                   'topic' => '1'}, pull_payload)
    svc.receive_pull_request
  end

  def service(*args)
    super Service::Typetalk, *args
  end

  def payload_for_push_test
    {
      'ref'        => 'refs/heads/master',
      'compare'    => 'https://github.com/dragon3/github-services/compare/06f63b43050935962f84fe54473a7c5de7977325...06f63b43050935962f84fe54473a7c5de7977326',
      'pusher'     => { 'name' => 'dragon3', },
      'commits'    => [
                       {'id' => '06f63b43050935962f84fe54473a7c5de7977325'},
                       {'id' => '06f63b43050935962f84fe54473a7c5de7977326'}],
      'repository' => {'name' => 'dragon3/github-services'},
    }
  end

end

