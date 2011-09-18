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

    def initialize
      @rooms = []
    end

    attr_reader :token, :logged_out

    def login(token, x)
      @token = token
    end

    def find_room_by_name(name)
      @rooms << (r=Room.new(name))
      r
    end

    def logout
      @logged_out = true
    end
  end

  def test_push
    svc = service({"token" => "t", "subdomain" => "s", "room" => "r"}, payload)
    svc.campfire = MockCampfire.new
    svc.receive_push
    assert svc.campfire.logged_out
    assert_equal 1, svc.campfire.rooms.size
    assert_equal 't', svc.campfire.token
    assert_equal 'r', svc.campfire.rooms.first.name
    assert_equal 4, svc.campfire.rooms.first.lines.size # 3 + summary
    assert svc.campfire.rooms.first.lines.first.match(/short/)
  end

  def test_push_non_master_with_master_only
    non_master_payload = payload
    non_master_payload["ref"] = "refs/heads/non-master"
    svc = service({"token" => "t", "subdomain" => "s", "room" => "r", "master_only" => 1}, non_master_payload)
    svc.campfire = MockCampfire.new
    svc.receive_push
    assert_equal 0, svc.campfire.rooms.size
  end

  def test_push_non_master_without_master_only
    non_master_payload = payload
    non_master_payload["ref"] = "refs/heads/non-master"
    svc = service({"token" => "t", "subdomain" => "s", "room" => "r", "master_only" => 0}, non_master_payload)
    svc.campfire = MockCampfire.new
    svc.receive_push
    assert_equal 4, svc.campfire.rooms.first.lines.size # 3 + summary
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

