class TrelloTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service :push,
      {'list_id' => 'abc123', 'consumer_token' => 'blarg'}, payload

    def svc.message_max_length; 4 end

    @stubs.post "/1/cards" do |env|
      assert_equal 'api.trello.com', env[:url].host
      assert_match 'token=blarg', env[:body]
      assert_match 'idList=abc123', env[:body]
      [200, {}, '']
    end

    assert_equal 'stub...', svc.send(:name_for_commit, svc.payload['commits'].first)

    assert_equal correct_description, svc.send(:desc_for_commit, svc.payload['commits'].first)

    svc.receive_push
  end

  private

  def correct_description
    'Author: Tom Preston-Werner

http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325

Repo: grit

Commit Message: stub git call for Grit#heads test f:15 Case#1'
  end

  def service(*args)
    super Service::Trello, *args
  end
end
