require 'test_helper'
require 'remote/credentials'

class RemoteCampfireTest < Test::Unit::TestCase

  def setup
    @subdomain = SUBDOMAIN
    @user, @pass = USER, PASS
    @ssl = SSL
    raise "Set your campfire credentials in /test/remote/credentials.rb before running the remote tests" unless @user && @pass && @subdomain
    @campfire = Tinder::Campfire.new @subdomain, :ssl => @ssl
  end

  def test_ssl_required
    if @ssl
      campfire = Tinder::Campfire.new @subdomain
      assert_raises(Tinder::SSLRequiredError) do
        campfire.login(@user, @pass)
      end
    end
  end

  def test_create_and_delete_room
    assert login
    assert @campfire.logged_in?

    room = @campfire.create_room("Testing#{Time.now.to_i}")

    assert_instance_of Tinder::Room, room
    assert_not_nil room.id

    room.name = "new name"
    assert_equal "new name", room.name

    room.destroy
    assert_nil @campfire.find_room_by_name(room.name)

    assert @campfire.logout
  ensure
    room.destroy rescue nil
  end

  def test_failed_login
    assert_raises(Tinder::Error) { @campfire.login(@user, 'notmypassword') }
    assert !@campfire.logged_in?
  end

  def test_find_nonexistent_room
    login
    assert_nil @campfire.find_room_by_name('No Room Should Have This Name')
  end

private

  def login(user = @user, pass = @pass)
    @campfire.login(user, pass)
  end

end
