require 'spec_helper'

describe "Preparing a campfire request" do
  before do
    @campfire = Tinder::Campfire.new("foobar")
    @request = Net::HTTP::Get.new("does_not_matter")
  end

  def prepare_request
    @campfire.send(:prepare_request, @request)
  end

  it "should return the request" do
    prepare_request.should equal(@request)
  end

  it "should set the cookie" do
    @campfire.instance_variable_set("@cookie", "foobar")
    prepare_request['Cookie'].should == 'foobar'
  end

  it "should set the user agent" do
    prepare_request['User-Agent'].should =~ /^Tinder/
  end
end

# describe "Performing a campfire request" do
#
#   before do
#     @response = mock("response")
#     Net::HTTP.any_instance.stubs(:request).returns(response)
#     request = Net::HTTP::Get.new("does_not_matter")
#     response.expects(:[]).with('set-cookie').and_return('foobar')
#     @campfire.send(:perform_request) { request }
#   end
#
#   it "should set cookie" do
#     @campfire.instance_variable_get("@cookie").should == 'foobar'
#   end
#
# end

describe "Verifying a 200 response" do

  before do
    @campfire = Tinder::Campfire.new("foobar")
    @response = mock("response")
    @response.should_receive(:code).and_return(200)
  end

  it "should return true when expecting success" do
    @campfire.send(:verify_response, @response, :success).should equal(true)
  end

  it "should return false when expecting a redirect" do
    @campfire.send(:verify_response, @response, :redirect).should equal(false)
  end

  it "should return false when expecting a redirect to a specific path" do
    @campfire.send(:verify_response, @response, :redirect_to => '/foobar').should equal(false)
  end

end

describe "Verifying a 302 response" do

  before do
    @campfire = Tinder::Campfire.new("foobar")
    @response = mock("response")
    @response.should_receive(:code).and_return(302)
  end

  it "should return true when expecting redirect" do
    @campfire.send(:verify_response, @response, :redirect).should equal(true)
  end

  it "should return false when expecting success" do
    @campfire.send(:verify_response, @response, :success).should equal(false)
  end

  it "should return true when expecting a redirect to a specific path" do
    @response.should_receive(:[]).with('location').and_return("/foobar")
    @campfire.send(:verify_response, @response, :redirect_to => '/foobar').should equal(true)
  end

  it "should return false when redirecting to a different path than expected" do
    @response.should_receive(:[]).with('location').and_return("/baz")
    @campfire.send(:verify_response, @response, :redirect_to => '/foobar').should equal(false)
  end

end

describe "A failed login" do

  before do
    @campfire = Tinder::Campfire.new 'foobar'
    @response = mock("response")
    @campfire.should_receive(:post).and_return(@response)
    @response.should_receive(:code).and_return("302")
    @response.should_receive(:[]).with("location").and_return("/login")
  end

  it "should raise an error" do
    lambda do
      @campfire.login "doesn't", "matter"
    end.should raise_error(Tinder::Error)
  end

  it "should not set logged in status" do
    @campfire.login 'foo', 'bar' rescue
    @campfire.logged_in?.should equal(false)
  end

end

describe "Accessing a room with guest access" do

  before do
    @room_id = 123
    @campfire = Tinder::Campfire.new 'foobar'
    @response = mock("response")
    @campfire.stub!(:post).and_return(@response)
  end

  it "should return a room for the public room" do
    @response.should_receive(:code).and_return(302)
    @response.should_receive(:[]).with("location").and_return("/rooms/#{@room_id}")

    room = @campfire.find_room_by_guest_hash "valid_hash", "John Doe"
    room.should be_kind_of(Tinder::Room)
  end

  it "should raise an error if given an invalid room hash" do
    @response.should_receive(:code).and_return(500)

    room = @campfire.find_room_by_guest_hash "invalid_hash", "John Doe"
    room.should be_nil
  end

end

describe "Accessing a room" do

  before do
    @request = mock("request")
    @response = mock("response")
    Net::HTTP.stub!(:new).and_return(@request)
    @request.stub!(:use_ssl=)
    @request.stub!(:request).and_return(@response)
    @response.stub!(:[]).and_return(true)
  end

  describe "when the room is full" do

    before do
      @html = File.read(File.dirname(__FILE__) + '/html/full_lobby.html')
      @response.stub!(:body).and_return(@html)
      @campfire = Tinder::Campfire.new 'foobar'
    end

    it "should return a room" do
      @campfire.rooms.should_not be_empty
    end

    it "should find a room by name" do
      @campfire.find_room_by_name("Just Fishin").class.should == Tinder::Room
    end

  end

  describe "when the room is not full" do

    before do
      @html = File.read(File.dirname(__FILE__) + '/html/normal_lobby.html')
      @response.stub!(:body).and_return(@html)
      @campfire = Tinder::Campfire.new 'foobar'
    end

    it "should return a room" do
      @campfire.rooms.should_not be_empty
    end

    it "should find a room by name" do
       @campfire.find_room_by_name("Just Fishin").class.should == Tinder::Room
     end
  end

end

describe "Accessing a room's transcript" do

  before do
    @room = Tinder::Room.new nil, 42
    @html = File.read(File.dirname(__FILE__) + '/html/transcript.html')
    @response = mock("response")
    @response.stub!(:body).and_return(@html)
    @room.stub!(:get).with("room/42/transcript/2009/05/05").
        and_return(@response)
    require 'time'
    @transcript = @room.transcript(Time.parse("2009-05-05"))
  end

  it "should return some messages" do
    @transcript.should_not be_empty
  end

  describe "the first message" do
      # This is a timestamp message
      it "should include a timestamp" do
        @transcript.first[:timestamp].should == Time.parse("2009-05-05 09:35")
      end
  end

  describe "the second message" do
      it "should include a timestamp" do
        @transcript.second[:timestamp].should == Time.parse("2009-05-05 09:35")
      end
  end

  describe "when entering the room" do
      it "a transcript message should include the person who entered" do
        @transcript.second[:person].should == "Marcel"
      end
  end
end
