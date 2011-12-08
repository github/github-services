require File.expand_path('../helper', __FILE__)

class EmailTest < Service::TestCase
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

  def test_smtp_settings
    svc = service(
      {'address' => 'a'},
      'payload')
    svc.email_config = {'address' => 'a', 'port' => '1', 'domain' => 'd'}
    assert_equal ['a', 1, 'd'], svc.smtp_settings
  end

  def test_smtp_settings_with_auth
    svc = service(
      {'address' => 'a'},
      'payload')
    svc.email_config = {'address' => 'a', 'port' => '1', 'domain' => 'd',
      'authentication' => 'au', 'user_name' => 'u', 'password' => 'p'}
    assert_equal ['a', 1, 'd', 'u', 'p', 'au'], svc.smtp_settings
  end

  def service(*args)
    svc = super Service::Email, *args
    def svc.messages
      @messages ||= []
    end

    def svc.send_message(msg, from, to)
      messages << [msg, from, to]
    end
    svc
  end
end



