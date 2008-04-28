require File.dirname(__FILE__) + '/../test_helper'

class RemoteCampfireTest < Test::Unit::TestCase
  
  def setup
    @campfire = Tinder::Campfire.new 'domain'
    # @user, @pass = 'email@example.com', 'password'
    raise "Set your campfire credentials before running the remote tests" unless @user && @pass
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