require File.expand_path('../helper', __FILE__)

class EmailTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service(
      {'address' => 'a'},
      payload)

    svc.receive_push

    msg, from, to = svc.messages.shift
    assert_match "noreply@github.com", from
    assert_equal 'a', to

    assert_nil svc.messages.shift
  end

  def test_multiple_address
    svc = service(
      {'address' => ' a b c'},
      payload)

    svc.receive_push

    msg, from, to = svc.messages.shift
    assert_match "noreply@github.com", from
    assert_equal 'a', to

    msg, from, to = svc.messages.shift
    assert_match "noreply@github.com", from
    assert_equal 'b', to

    # 3rd address ignored
    assert_nil svc.messages.shift
  end

  def test_push_from_author
    svc = service(
      {'address' => 'a', 'send_from_author' => '1'},
      payload)

    svc.receive_push

    msg, from, to = svc.messages.shift
    assert_match 'tom@mojombo.com', from
    assert_equal 'a', to

    assert_nil svc.messages.shift
  end

  def test_show_diff
    payload['commits'].each do |commit|
      @stubs.get commit['url'].sub(/http:\/\/[^\/]+/, '')+".diff" do |env|
        [200, {}, 'This is my diff']
      end
    end

    svc = service(
      {'address' => 'a', 'show_diff' => '1'},
      payload)

    svc.receive_push

    msg, from, to = svc.messages.shift
    assert_match 'This is my diff', msg

    assert_nil svc.messages.shift
  end

  def service(*args)
    svc = super Service::Email, *args
    def svc.messages
      @messages ||= []
    end

    def svc.send_mail(mail)
      messages << [mail.to_s, mail.from.first, mail.to.first]
    end
    svc
  end
end



