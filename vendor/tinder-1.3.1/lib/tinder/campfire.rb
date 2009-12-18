module Tinder

  # == Usage
  #
  #   campfire = Tinder::Campfire.new 'mysubdomain'
  #   campfire.login 'myemail@example.com', 'mypassword'
  #
  #   room = campfire.create_room 'New Room', 'My new campfire room to test tinder'
  #   room.speak 'Hello world!'
  #   room.destroy
  #
  #   room = campfire.find_room_by_guest_hash 'abc123', 'John Doe'
  #   room.speak 'Hello world!'
  class Campfire
    HOST = "campfirenow.com"

    attr_reader :connection, :subdomain, :uri

    # Create a new connection to the campfire account with the given +subdomain+.
    #
    # == Options:
    # * +:ssl+: use SSL for the connection, which is required if you have a Campfire SSL account.
    #           Defaults to false
    # * +:proxy+: a proxy URI. (e.g. :proxy => 'http://user:pass@example.com:8000')
    #
    #   c = Tinder::Campfire.new("mysubdomain", :ssl => true)
    def initialize(subdomain, options = {})
      options = { :ssl => false }.merge(options)
      @connection = Connection.new
      @cookie = nil
      @subdomain = subdomain
      @uri = URI.parse("#{options[:ssl] ? 'https' : 'http' }://#{subdomain}.#{HOST}")
      connection.base_uri @uri.to_s
      if options[:proxy]
        uri = URI.parse(options[:proxy])
        @http = Net::HTTP::Proxy(uri.host, uri.port, uri.user, uri.password)
      else
        @http = Net::HTTP
      end
      @logged_in = false
    end

    # Log in to campfire using your +email+ and +password+
    def login(username, password)
      connection.basic_auth(username, password)
      @logged_in = true
    end

    # Returns true when successfully logged in
    def logged_in?
      @logged_in == true
    end

    def logout
      connection.default_options.delete(:basic_auth)
      @logged_in = false
    end

    # Get an array of all the available rooms
    # TODO: detect rooms that are full (no link)
    def rooms
      connection.get('/rooms.json')['rooms'].map do |room|
        Room.new(self, room)
      end
    end

    # Find a campfire room by name
    def find_room_by_name(name)
      rooms.detect { |room| room.name == name }
    end

    # Find a campfire room by its guest hash
    def find_room_by_guest_hash(hash, name)
      rooms.detect { |room| room.guest_invite_code == hash }
    end

    # Creates and returns a new Room with the given +name+ and optionally a +topic+
    def create_room(name, topic = nil)
      connection.post('/rooms.json', :body => { :room => { :name => name, :topic => topic } }.to_json)
      find_room_by_name(name)
    end

    def find_or_create_room_by_name(name)
      find_room_by_name(name) || create_room(name)
    end

    # List the users that are currently chatting in any room
    def users(*room_names)
      rooms.map(&:users).flatten.compact.uniq.sort
    end

    # Get the dates of the available transcripts by room
    #
    #   campfire.available_transcripts
    #   #=> {"15840" => [#<Date: 4908311/2,0,2299161>, #<Date: 4908285/2,0,2299161>]}
    #
    def available_transcripts(room = nil)
      raise NotImplementedError
    end

    # Is the connection to campfire using ssl?
    def ssl?
      uri.scheme == 'https'
    end
  end
end
