require File.expand_path('../helper', __FILE__)

class CampfireTest < Service::TestCase
  class MockCampfire
    class Room
      attr_reader :name, :lines

      def initialize(name)
        @name  = name
        @lines = []
      end

      def speak(line)
        @lines << line
      end
    end

    attr_reader :rooms

    def initialize(subd, options = {})
      @subdomain = subd
      @rooms     = []
      @options   = options
      @token     = options[:token]
    end

    attr_reader :subdomain, :token

    def find_room_by_name(name)
      @rooms << (r=Room.new(name))
      r
    end
  end

  def test_push
    svc = service({"token" => "t", "subdomain" => "s", "room" => "r"}, payload)
    svc.receive_push
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 4, svc.campfire.rooms.first.lines.size # 3 + summary
    assert svc.campfire.rooms.first.lines.first.match(/short/)
  end

  def test_issues
    svc = service(:issues, {"token" => "t", "subdomain" => "s", "room" => "r"}, issues_payload)
    svc.receive_issues
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # 3 + summary
    assert_match /\[grit\] defunkt opened issue #5: booya./i, svc.campfire.rooms.first.lines.first
  end

  def test_pull
    svc = service(:pull_request, {"token" => "t", "subdomain" => "s", "room" => "r"}, pull_payload)
    svc.receive_pull_request
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # 3 + summary
    assert_match /\[grit\] defunkt opened pull request #5: booya \(master...feature\)/i, svc.campfire.rooms.first.lines.first
  end

  def test_public
    svc = service(:public, {"token" => "t", "subdomain" => "s", "room" => "r"}, public_payload)
    svc.receive_public
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # 3 + summary
    assert_match /\[grit\] defunkt made the repository public/i, svc.campfire.rooms.first.lines.first
  end

  def test_gollum
    svc = service(:gollum, {"token" => "t", "subdomain" => "s", "room" => "r"}, gollum_payload)
    svc.receive_public
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # 3 + summary
    assert_match /\[grit\] defunkt created wiki page Foo/i, svc.campfire.rooms.first.lines.first
  end

  def test_gollum_multiple_pages
    multiple_page_payload = gollum_payload
    multiple_page_payload['pages'] << multiple_page_payload['pages'][0].merge(
      'title' => 'Bar',
      'html_url' => 'https://github.com/mojombo/magik/wiki/Bar',
    )

    svc = service(:gollum, {"token" => "t", "subdomain" => "s", "room" => "r"}, multiple_page_payload)
    svc.receive_public
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # 3 + summary
    assert_match /\[grit\] defunkt created 2 wiki pages/i, svc.campfire.rooms.first.lines.first
  end

  def test_gollum_multiple_actions
    multiple_action_payload = gollum_payload
    multiple_action_payload['pages'] << multiple_action_payload['pages'][0].merge(
      'title' => 'Bar',
      'html_url' => 'https://github.com/mojombo/magik/wiki/Bar',
      'action' => 'updated'
    )

    svc = service(:gollum, {"token" => "t", "subdomain" => "s", "room" => "r"}, multiple_action_payload)
    svc.receive_public
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 1, svc.campfire.rooms.first.lines.size # 3 + summary
    assert_match /\[grit\] defunkt created 1 and updated 1 wiki pages/i, svc.campfire.rooms.first.lines.first
  end

  def test_full_domain
    svc = service({"token" => "t", "subdomain" => "s.campfirenow.com", "room" => "r"}, payload)
    svc.receive_push
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 4, svc.campfire.rooms.first.lines.size # 3 + summary
    assert svc.campfire.rooms.first.lines.first.match(/short/)
  end

  def test_long_url
    svc = service({"token" => "t", "subdomain" => "s", "room" => "r", "long_url" => "1"}, payload)
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    svc.receive_push
    assert svc.campfire.rooms.first.lines.first.match(/github\.com/), "Summary url should not be shortened"
  end

  def test_push_non_master_with_master_only
    non_master_payload = payload
    non_master_payload["ref"] = "refs/heads/non-master"
    svc = service({"token" => "t", "subdomain" => "s", "room" => "r", "master_only" => 1}, non_master_payload)
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    svc.receive_push
    assert_equal 0, svc.campfire.rooms.size
  end

  def test_push_non_master_without_master_only
    non_master_payload = payload
    non_master_payload["ref"] = "refs/heads/non-master"
    svc = service({"token" => "t", "subdomain" => "s", "room" => "r", "master_only" => 0}, non_master_payload)
    assert_equal 's', svc.campfire.subdomain
    assert_equal 't', svc.campfire.token
    svc.receive_push
    assert_equal 4, svc.campfire.rooms.first.lines.size # 3 + summary
  end

  def setup
    Service::Campfire.campfire_class = MockCampfire
  end

  def teardown
    Service::Campfire.campfire_class = Tinder::Campfire
  end

  def service(*args)
    svc = super(Service::Campfire, *args)
    class << svc
      def shorten_url(*args)
        'short'
      end
    end

    svc
  end
end
