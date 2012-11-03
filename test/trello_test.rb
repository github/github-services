require File.expand_path('../helper', __FILE__)

class TrelloTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @data = {'push_list_id' => 'abc123', 'consumer_token' => 'blarg', 'master_only' => 1}
  end

  def test_push
    svc = service :push, @data

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

  def test_backward_compatible_push_list_id
    @data['list_id'] = @data['push_list_id']
    @data.delete 'push_list_id'
    svc = service :push, @data
    assert_cards_created svc
  end

  def test_master_only_no_master
    svc = service :push,
      @data.update("master_only" => 1),
      payload.update("ref" => "refs/heads/non-master")

    assert_no_cards_created svc
  end

  def test_master_only_master
    svc = service :push, @data.update("master_only" => 1)
    assert_cards_created svc
  end

  def test_ignore_regex
    svc = service :push, @data.merge!("ignore_regex" => "Grit|throughout|heads")
    assert_no_cards_created svc
  end

  def test_no_ignore_regex
    svc = service :push, @data.merge!("ignore_regex" => "")
    assert_cards_created svc
  end

  def test_pull_request
    svc = service :pull_request, @data.merge!("pull_request_list_id" => 'zxy987')
    assert_cards_created svc, :pull_request
  end
  
  def test_closed_pull_request
    svc = service :pull_request, 
                  @data.merge!("pull_request_list_id" => 'zxy987'), 
                  pull_payload.merge!("action" => "closed")
    assert_no_cards_created svc, :pull_request
  end

  private
  
  def call_hook_on_service svc, method
    case method
      when :push
        svc.receive_push
      when :pull_request
        svc.receive_pull_request
    end
  end

  def assert_cards_created(svc, method = :push)
    @stubs.post "/1/cards" do |env|
      assert_equal 'api.trello.com', env[:url].host
      [200, {}, '']
    end
    call_hook_on_service svc, method
  end

  def assert_no_cards_created(svc, method = :push)
    @stubs.post "/1/cards" do
      raise "This should not be called"
    end
    call_hook_on_service svc, method
  end

  def correct_description
    'Author: Tom Preston-Werner

http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325

Repo: grit

Branch: master

Commit Message: stub git call for Grit#heads test f:15 Case#1'
  end

  def service(*args)
    super Service::Trello, *args
  end
end
