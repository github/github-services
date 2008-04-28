module Tinder
  # A campfire room
  class Room
    attr_reader :id, :name

    def initialize(campfire, id, name = nil)
      @campfire = campfire
      @id = id
      @name = name
    end
    
    # Join the room. Pass +true+ to join even if you've already joined.
    def join(force = false)
      @room = returning(get("room/#{id}")) do |room|
        raise Error, "Could not join room" unless verify_response(room, :success)
        @membership_key = room.body.scan(/\"membershipKey\": \"([a-z0-9]+)\"/).to_s
        @user_id = room.body.scan(/\"userID\": (\d+)/).to_s
        @last_cache_id = room.body.scan(/\"lastCacheID\": (\d+)/).to_s
        @timestamp = room.body.scan(/\"timestamp\": (\d+)/).to_s
        @idle_since = Time.now
      end if @room.nil? || force
      ping
      true
    end
    
    # Leave a room
    def leave
      returning verify_response(post("room/#{id}/leave"), :redirect) do
        @room, @membership_key, @user_id, @last_cache_id, @timestamp, @idle_since = nil
      end
    end

    # Toggle guest access on or off
    def toggle_guest_access
      # re-join the room to get the guest url
      verify_response(post("room/#{id}/toggle_guest_access"), :success) && join(true)
    end

    # Get the url for guest access
    def guest_url
      join
      link = (Hpricot(@room.body)/"#guest_access h4").first
      link.inner_html if link
    end
    
    def guest_access_enabled?
      join
      !guest_url.nil?
    end

    # The invite code use for guest
    def guest_invite_code
      join
      guest_url.scan(/\/(\w*)$/).to_s
    end

    # Change the name of the room
    def name=(name)
      @name = name if verify_response(post("account/edit/room/#{id}", { :room => { :name => name }}, :ajax => true), :success)
    end
    alias_method :rename, :name=

    # Change the topic
    def topic=(topic)
      topic if verify_response(post("room/#{id}/change_topic", { 'room' => { 'topic' => topic }}, :ajax => true), :success)
    end
    
    # Get the current topic
    def topic
      join
      h = (Hpricot(@room.body)/"#topic")
      if h
        (h/:span).remove
        h.inner_text.strip
      end
    end
    
    # Lock the room to prevent new users from entering and to disable logging
    def lock
      verify_response(post("room/#{id}/lock", {}, :ajax => true), :success)
    end

    # Unlock the room
    def unlock
      verify_response(post("room/#{id}/unlock", {}, :ajax => true), :success)
    end

    def ping(force = false)
      returning verify_response(post("room/#{id}/tabs", { }, :ajax => true), :success) do
        @idle_since = Time.now
      end if @idle_since < 1.minute.ago || force
    end

    def destroy
      verify_response(post("account/delete/room/#{id}"), :success)
    end

    # Post a new message to the chat room
    def speak(message, options = {})
      join
      message if verify_response(post("room/#{id}/speak", {:message => message,
        :t => Time.now.to_i}.merge(options), :ajax => true), :success)
    end

    def paste(message)
      join
      speak message, :paste => true
    end
    
    # Get the list of users currently chatting for this room
    def users
      @campfire.users name
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
      join
      if block_given?
        catch(:stop_listening) do
          trap('INT') { throw :stop_listening }
          loop do
            ping
            self.messages.each {|msg| yield msg }
            sleep interval
          end
        end
      else
        self.messages
      end
    end
    
    # Get the dates for the available transcripts for this room
    def available_transcripts
      @campfire.available_transcripts(id)
    end
    
    # Get the transcript for the given date (Returns a hash in the same format as #listen)
    #
    #   room.transcript(room.available_transcripts.first)
    #   #=> [{:message=>"foobar!", :user_id=>"99999", :person=>"Brandon", :id=>"18659245"}]
    #
    def transcript(date)
      (Hpricot(get("room/#{id}/transcript/#{date.to_date.strftime('%Y/%m/%d')}").body) / ".message").collect do |message|
        person = (message / '.person span').first
        body = (message / '.body div').first
        {:id => message.attributes['id'].scan(/message_(\d+)/).to_s,
          :person => person ? person.inner_html : nil,
          :user_id => message.attributes['class'].scan(/user_(\d+)/).to_s,
          :message => body ? body.inner_html : nil
        }
      end
    end

  protected

    def messages
      returning [] do |messages|
        response = post("poll.fcgi", {:l => @last_cache_id, :m => @membership_key,
          :s => @timestamp, :t => "#{Time.now.to_i}000"}, :ajax => true)
        if response.body.length > 1
          # deal with "chat.redirectTo('/');" - relogin
          join(true) && self.messages if response.body.match('chat\.redirectTo')

          lines = response.body.split("\r\n")
          
          if lines.length > 0
            @last_cache_id = lines.pop.scan(/chat.poller.lastCacheID = (\d+)/).to_s
            lines.each do |msg|
              unless msg.match(/timestamp_message/)
                # pull out only the chat.transcript.queueMessage part for now
                msg = msg.scan(/(chat\.transcript\.queueMessage(?:.+?);)/).to_s
                if msg.length > 0
                  messages << {
                    :id => msg.scan(/message_(\d+)/).to_s,
                    :user_id => msg.scan(/user_(\d+)/).to_s,
                    :person => msg.scan(/\\u003Ctd class=\\"person\\"\\u003E(?:\\u003Cspan\\u003E)?(.+?)(?:\\u003C\/span\\u003E)?\\u003C\/td\\u003E/).to_s,
                    :message => msg.scan(/\\u003Ctd class=\\"body\\"\\u003E\\u003Cdiv\\u003E(.+?)\\u003C\/div\\u003E\\u003C\/td\\u003E/).to_s
                  }
                end
              end
            end
          end
        end
      end
    end
  
    [:post, :get, :verify_response].each do |method|
      define_method method do |*args|
        @campfire.send method, *args
      end
    end

  end
end
