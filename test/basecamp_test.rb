require File.expand_path('../helper', __FILE__)

class BasecampTest < Service::TestCase
  def test_receives_push
    svc = service :push, {}, payload
    svc.receive_push

    assert msg = svc.basecamp.messages.shift
    assert_equal 1, project_id = msg.shift
    msg = msg.shift # now its the hash
    assert_equal 2, msg[:category_id]
    assert msg.key?(:title)
    assert msg.key?(:body)
  end

  def service(*args)
    svc = super Service::Basecamp, *args
    svc.basecamp = Fakecamp.new
    svc.project_id  = 1
    svc.category_id = 2
    svc
  end

  class Fakecamp
    attr_reader :messages

    def initialize
      @messages = []
    end

    def post_message(*args)
      @messages << args
    end
  end
end
