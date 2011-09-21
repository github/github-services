require File.expand_path("../helper", __FILE__)

class GemnasiumTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_stripped_user
    svc = service("user" => " laserlemon ")
    assert_equal "laserlemon", svc.user
  end

  def test_stripped_token
    svc = service("token" => " abc ")
    assert_equal "abc", svc.token
  end

  def test_downcased_token
    svc = service("token" => "ABC")
    assert_equal "abc", svc.token
  end

  def test_body
    svc = service({}, {"pay" => "load"})
    assert_equal '{"pay":"load"}', svc.body
  end

  def test_signature
    svc = service({"token" => "abc"}, {"pay" => "load"})
    assert_equal "f329edd3feef6b4504c15ee4af6cb65ba28de90ba690001e3a548c5dddf80990", svc.signature
  end

  def test_push
    svc = service({"user" => "laserlemon", "token" => "abc"}, {"pay" => "load"})

    @stubs.post "/repositories/hook" do |env|
      assert_equal "gemnasium.com", env[:url].host
      assert_equal "application/json", env[:request_headers][:content_type]
      assert_equal "Basic bGFzZXJsZW1vbjpmMzI5ZWRkM2ZlZWY2YjQ1MDRjMTVlZTRhZjZjYjY1YmEyOGRlOTBiYTY5MDAwMWUzYTU0OGM1ZGRkZjgwOTkw", env[:request_headers][:authorization]
      assert_equal '{"pay":"load"}', env[:body]
    end

    svc.receive_push
  end

  private
    def service(data, payload = payload)
      super(Service::Gemnasium, data, payload)
    end
end
