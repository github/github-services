module Tinder
  # A campfire room
  class Room
    attr_reader :id, :name

    def initialize(campfire, attributes = {})
      @campfire = campfire
      @id = attributes['id']
      @name = attributes['name']
      @loaded = false
    end

    # Join the room. Pass +true+ to join even if you've already joined.
    def join(force = false)
      post 'join'
    end

    # Leave a room
    def leave
      post 'leave'
    end

    # Toggle guest access on or off
    def toggle_guest_access
      raise NotImplementedError
    end

    # Get the url for guest access
    def guest_url
      if guest_access_enabled?
        "http://#{@campfire.subdomain}.campfirenow.com/#{guest_invite_code}"
      else
        nil
      end
    end

    def guest_access_enabled?
      load
      @open_to_guests ? true : false
    end

    # The invite code use for guest
    def guest_invite_code
      load
      @active_token_value
    end

    # Change the name of the room
    def name=(name)
      connection.post("/room/#{@id}.json", :body => { :room => { :name => name } })
    end
    alias_method :rename, :name=

    # Change the topic
    def topic=(topic)
      connection.post("/room/#{@id}.json", :body => { :room => { :topic => name } })
    end

    # Get the current topic
    def topic
      load
      @topic
    end

    # Lock the room to prevent new users from entering and to disable logging
    def lock
      post :lock
    end

    # Unlock the room
    def unlock
      post :unlock
    end

    def ping(force = false)
      raise NotImplementedError
    end

    def destroy
      raise NotImplementedError
    end

    # Post a new message to the chat room
    def speak(message, options = {})
      send_message(message)
    end

    def paste(message)
      send_message(message, 'PasteMessage')
    end

    def play(sound)
      send_message(sound, 'SoundMessage')
    end

    # Get the list of users currently chatting for this room
    def users
      reload!
      @users
    end

    # Get and array of the messages that have been posted to the room. Each
    # messages is a hash with:
    # * +:person+: the display name of the person that posted the message
    # * +:message+: the body of the message
    # * +:user_id+: Campfire user id
    # * +:id+: Campfire message id
    #
    #   room.listen
    #   #=> [{:person=>"Brandon", :message=>"I'm getting very sleepy", :user_id=>"148583", :id=>"16434003"}]
    #
    # Called without a block, listen will return an array of messages that have been
    # posted since you joined. listen also takes an optional block, which then polls
    # for new messages every 5 seconds and calls the block for each message.
    #
    #   room.listen do |m|
    #     room.speak "#{m[:person]}, Go away!" if m[:message] =~ /Java/i
    #   end
    #
    def listen(interval = 5)
      require 'yajl/http_stream'

      auth = connection.default_options[:basic_auth]
      url = URI.parse("http://#{auth[:username]}:#{auth[:password]}@streaming.#{Campfire::HOST}/room/#{@id}/live.json")
      Yajl::HttpStream.get(url) do |message|
        { :id => message['id'],
          :user_id => message['user_id'],
          :message => message['body'] }
      end
    end

    # Get the dates for the available transcripts for this room
    def available_transcripts
      raise NotImplementedError
    end

    # Get the transcript for the given date (Returns a hash in the same format as #listen)
    #
    #   room.transcript(room.available_transcripts.first)
    #   #=> [{:message=>"foobar!",
    #         :user_id=>"99999",
    #         :person=>"Brandon",
    #         :id=>"18659245",
    #         :timestamp=>=>Tue May 05 07:15:00 -0700 2009}]
    #
    # The timestamp slot will typically have a granularity of five minutes.
    #
    def transcript(transcript_date)
      url = "/room/#{@id}/transcript/#{transcript_date.to_date.strftime('%Y/%m/%d')}.json"
      connection.get(url)['messages'].map do |room|
        { :id => room['id'],
          :user_id => room['user_id'],
          :message => room['body'],
          :timestamp => Time.parse(room['created_at']) }
      end
    end

    def upload(filename)
      File.open(filename, "rb") do |file|
        params = Multipart::MultipartPost.new('upload' => file)
        connection.post("/room/#{@id}/uploads.json", :body => params.query)
      end
    end

    # Get the list of latest files for this room
    def files(count = 5)
      connection.get(room_url_for(:uploads))['uploads'].map { |u| u['full_url'] }
    end

    protected
      def load
        reload! unless @loaded
      end

      def reload!
        attributes = connection.get("/room/#{@id}.json")['room']

        @id = attributes['id']
        @name = attributes['name']
        @topic = attributes['topic']
        @full = attributes['full']
        @open_to_guests = attributes['open-to-guests']
        @active_token_value = attributes['active-token-value']
        @users = attributes['users'].map { |u| u['name'] }

        @loaded = true
      end

      def send_message(message, type = 'Textmessage')
        post 'speak', :body => {:message => {:body => message, :type => type}}.to_json
      end

      def get(action, options = {})
        connection.get(room_url_for(action), options)
      end

      def post(action, options = {})
        connection.post(room_url_for(action), options)
      end

      def room_url_for(action)
        "/room/#{@id}/#{action}.json"
      end

      def connection
        @campfire.connection
      end
  end
end
