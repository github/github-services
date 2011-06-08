require File.expand_path('../helper', __FILE__)

class GetLocalizationTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service({
      'project_name' => 'n',
      'project_token' => 't'}, 'a' => 1)

    @stubs.post "/services/github/notify/n/t/" do |env|
      assert_match /payload=%7B%22a%22%3A1%7D($|\&)/, env[:body]
      [200, {}, '']
    end

    svc.receive_push
  end

  def service(*args)
    super Service::GetLocalization, *args
  end
end

