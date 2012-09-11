require File.expand_path('../helper', __FILE__)

class BacklogTest < Service::TestCase
  def setup
    @server = FakeXMLRPC.new()
  end

  def test_push
    modified_payload = modify_payload(payload)
    svc = service({'api_url' => 'https://demo.backlog.jp/XML-RPC', 'user_id' => 'someone', 'password' => '12345'}, modified_payload)
    svc.xmlrpc_client = @server
    svc.receive_push

    assert @server.commented.length == 1
    assert @server.commented[0]['content'].include? '06f63b43050935962f84fe54473a7c5de7977325'
    assert @server.switched.length == 2
    assert @server.switched[0]['comment'].include? '5057e76a11abd02e83b7d3d3171c4b68d9c88480'
    assert @server.switched[0]['status'] == 3
    assert @server.switched[1]['comment'].include? 'a47fd41f3aa4610ea527dcc1669dfdb9c15c5425'
    assert @server.switched[1]['status'] == 4
  end

  def modify_payload(payload)
    modified_payload = payload.clone()
    modified_payload['commits'][0]['message'] << "\nDORA-1"
    modified_payload['commits'][1]['message'] << "\nDORA-2 #fixed"
    modified_payload['commits'][2]['message'] << "\nDORA-3 #closed"
    return modified_payload
  end

  def service(*args)
    super Service::Backlog, *args
  end

  class FakeXMLRPC
    def call(procedure, arguments)
      case procedure
      when 'backlog.addComment'
        commented << {'key' => arguments['key'], 'content' => arguments['content']}
      when 'backlog.switchStatus'
        switched << { 'key' => arguments['key'], 'comment' => arguments['comment'], 'status' => arguments['statusId']}
      end
    end

    def commented
      @commented ||= []
    end

    def switched
      @switched ||= []
    end
  end
end

