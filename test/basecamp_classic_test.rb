require File.expand_path('../helper', __FILE__)

class BasecampClassicTest < Service::TestCase
  def test_receives_push
    svc = service :push, {'url' => 'https://foo.com', 'username' => 'monkey', 'password' => 'abc'}, payload
    svc.receive

    assert msg = svc.messages.shift
    assert_equal 2, msg.category_id
    assert msg.title.present?
    assert msg.body.present?
  end

  def service(*args)
    svc = super Service::BasecampClassic, *args

    svc.project_id  = 1
    svc.category_id = 2

    def svc.messages
      @messages ||= []
    end

    def svc.post_message(options = {})
      messages << build_message(options)
    end

    svc
  end
end
