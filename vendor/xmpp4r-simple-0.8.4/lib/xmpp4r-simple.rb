# Jabber::Simple - An extremely easy-to-use Jabber client library.
# Copyright 2006 Blaine Cook <blaine@obvious.com>, Obvious Corp.
# 
# Jabber::Simple is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# Jabber::Simple is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Jabber::Simple; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster'

module Jabber

  class ConnectionError < StandardError #:nodoc:
  end
  
  class Contact #:nodoc:

    def initialize(client, jid)
      @jid = jid.respond_to?(:resource) ? jid : JID.new(jid)
      @client = client
    end

    def inspect
      "Jabber::Contact #{jid.to_s}"
    end

    def subscribed?
      [:to, :both].include?(subscription)
    end

    def subscription
      roster_item && roster_item.subscription
    end

    def ask_for_authorization!
      subscription_request = Presence.new.set_type(:subscribe)
      subscription_request.to = jid
      client.send!(subscription_request)
    end
    
    def unsubscribe!
      unsubscription_request = Presence.new.set_type(:unsubscribe)
      unsubscription_request.to = jid
      client.send!(unsubscription_request)
      client.send!(unsubscription_request.set_type(:unsubscribed))
    end

    def jid(bare=true)
      bare ? @jid.strip : @jid
    end

    private

    def roster_item
      client.roster.items[jid]
    end
   
    def client
      @client
    end
  end

  class Simple

    # Create a new Jabber::Simple client. You will be automatically connected
    # to the Jabber server and your status message will be set to the string
    # passed in as the status_message argument.
    #
    # jabber = Jabber::Simple.new("me@example.com", "password", "Chat with me - Please!")
    def initialize(jid, password, status = nil, status_message = "Available")
      @jid = jid
      @password = password
      @disconnected = false
      status(status, status_message)
      start_deferred_delivery_thread
    end

    def inspect #:nodoc:
      "Jabber::Simple #{@jid}"
    end
    
    # Send a message to jabber user jid.
    #
    # Valid message types are:
    # 
    #   * :normal (default): a normal message.
    #   * :chat: a one-to-one chat message.
    #   * :groupchat: a group-chat message.
    #   * :headline: a "headline" message.
    #   * :error: an error message.
    #
    # If the recipient is not in your contacts list, the message will be queued
    # for later delivery, and the Contact will be automatically asked for
    # authorization (see Jabber::Simple#add).
    def deliver(jid, message, type=:chat)
      contacts(jid) do |friend|
        unless subscribed_to? friend
          add(friend.jid)
          return deliver_deferred(friend.jid, message, type)
        end
        msg = Message.new(friend.jid)
        msg.type = type
        msg.body = message
        send!(msg)
      end
    end

    # Set your presence, with a message.
    #
    # Available values for presence are:
    # 
    #   * nil: online.
    #   * :chat: free for chat.
    #   * :away: away from the computer.
    #   * :dnd: do not disturb.
    #   * :xa: extended away.
    #
    # It's not possible to set an offline status - to do that, disconnect! :-)
    def status(presence, message)
      @presence = presence
      @status_message = message
      stat_msg = Presence.new(@presence, @status_message)
      send!(stat_msg)
    end
  
    # Ask the users specified by jids for authorization (i.e., ask them to add
    # you to their contact list). If you are already in the user's contact list,
    # add() will not attempt to re-request authorization. In order to force
    # re-authorization, first remove() the user, then re-add them.
    #
    # Example usage:
    # 
    #   jabber_simple.add("friend@friendosaurus.com")
    #
    # Because the authorization process might take a few seconds, or might
    # never happen depending on when (and if) the user accepts your
    # request, results are placed in the Jabber::Simple#new_subscriptions queue.
    def add(*jids)
      contacts(*jids) do |friend|
        next if subscribed_to? friend
        friend.ask_for_authorization!
      end
    end

    # Remove the jabber users specified by jids from the contact list.
    def remove(*jids)
      contacts(*jids) do |unfriend|
        unfriend.unsubscribe!
      end
    end

    # Returns true if this Jabber account is subscribed to status updates for
    # the jabber user jid, false otherwise.
    def subscribed_to?(jid)
      contacts(jid) do |contact|
        return contact.subscribed?
      end
    end

    # If contacts is a single contact, returns a Jabber::Contact object
    # representing that user; if contacts is an array, returns an array of
    # Jabber::Contact objects.
    #
    # When called with a block, contacts will yield each Jabber::Contact object
    # in turn. This is mainly used internally, but exposed as an utility
    # function.
    def contacts(*contacts, &block)
      @contacts ||= {}
      contakts = []
      contacts.each do |contact|
        jid = contact.to_s
        unless @contacts[jid]
          @contacts[jid] = contact.respond_to?(:ask_for_authorization!) ? contact : Contact.new(self, contact)
        end
        yield @contacts[jid] if block_given?
        contakts << @contacts[jid]
      end
      contakts.size > 1 ? contakts : contakts.first
    end

    # Returns true if the Jabber client is connected to the Jabber server,
    # false otherwise.
    def connected?
      @client ||= nil
      connected = @client.respond_to?(:is_connected?) && @client.is_connected?
      return connected
    end

    # Returns an array of messages received since the last time
    # received_messages was called. Passing a block will yield each message in
    # turn, allowing you to break part-way through processing (especially
    # useful when your message handling code is not thread-safe (e.g.,
    # ActiveRecord).
    #
    # e.g.:
    #
    #   jabber.received_messages do |message|
    #     puts "Received message from #{message.from}: #{message.body}"
    #   end
    def received_messages(&block)
      dequeue(:received_messages, &block)
    end

    # Returns true if there are unprocessed received messages waiting in the
    # queue, false otherwise.
    def received_messages?
      !queue(:received_messages).empty?
    end

    # Returns an array of presence updates received since the last time
    # presence_updates was called. Passing a block will yield each update in
    # turn, allowing you to break part-way through processing (especially
    # useful when your presence handling code is not thread-safe (e.g.,
    # ActiveRecord).
    #
    # e.g.:
    #
    #   jabber.presence_updates do |friend, new_presence|
    #     puts "Received presence update from #{friend}: #{new_presence}"
    #   end
    def presence_updates(&block)
      updates = []
      @presence_mutex.synchronize do
        dequeue(:presence_updates) do |friend|
          presence = @presence_updates[friend]
          next unless presence
          new_update = [friend, presence[0], presence[1]]
          yield new_update if block_given?
          updates << new_update
          @presence_updates.delete(friend)
        end
      end
      return updates
    end
    
    # Returns true if there are unprocessed presence updates waiting in the
    # queue, false otherwise.
    def presence_updates?
      !queue(:presence_updates).empty?
    end

    # Returns an array of subscription notifications received since the last
    # time new_subscriptions was called. Passing a block will yield each update
    # in turn, allowing you to break part-way through processing (especially
    # useful when your subscription handling code is not thread-safe (e.g.,
    # ActiveRecord).
    #
    # e.g.:
    #
    #   jabber.new_subscriptions do |friend, presence|
    #     puts "Received presence update from #{friend.to_s}: #{presence}"
    #   end
    def new_subscriptions(&block)
      dequeue(:new_subscriptions, &block)
    end
    
    # Returns true if there are unprocessed presence updates waiting in the
    # queue, false otherwise.
    def new_subscriptions?
      !queue(:new_subscriptions).empty?
    end
    
    # Returns an array of subscription notifications received since the last
    # time subscription_requests was called. Passing a block will yield each update
    # in turn, allowing you to break part-way through processing (especially
    # useful when your subscription handling code is not thread-safe (e.g.,
    # ActiveRecord).
    #
    # e.g.:
    #
    #   jabber.subscription_requests do |friend, presence|
    #     puts "Received presence update from #{friend.to_s}: #{presence}"
    #   end
    def subscription_requests(&block)
      dequeue(:subscription_requests, &block)
    end
 
    # Returns true if auto-accept subscriptions (friend requests) is enabled
    # (default), false otherwise.
    def accept_subscriptions?
      @accept_subscriptions = true if @accept_subscriptions.nil?
      @accept_subscriptions
    end

    # Change whether or not subscriptions (friend requests) are automatically accepted.
    def accept_subscriptions=(accept_status)
      @accept_subscriptions = accept_status
    end
    
    # Direct access to the underlying Roster helper.
    def roster
      return @roster if @roster
      self.roster = Roster::Helper.new(client)
    end

    # Direct access to the underlying Jabber client.
    def client
      connect!() unless connected?
      @client
    end
    
    # Send a Jabber stanza over-the-wire.
    def send!(msg)
      attempts = 0
      begin
        attempts += 1
        client.send(msg)
      rescue Errno::EPIPE, IOError => e
        sleep 0.33
        disconnect
        reconnect
        retry unless attempts > 3
        raise e
      end
    end

    # Use this to force the client to reconnect after a force_disconnect.
    def reconnect
      @disconnected = false
      connect!
    end

    # Use this to force the client to disconnect and not automatically
    # reconnect.
    def disconnect
      disconnect!
    end
    
    # Queue messages for delivery once a user has accepted our authorization
    # request. Works in conjunction with the deferred delivery thread.
    #
    # You can use this method if you want to manually add friends and still
    # have the message queued for later delivery.
    def deliver_deferred(jid, message, type)
      msg = {:to => jid, :message => message, :type => type}
      queue(:pending_messages) << [msg]
    end

    private

    def client=(client)
      self.roster = nil # ensure we clear the roster, since that's now associated with a different client.
      @client = client
    end

    def roster=(new_roster)
      @roster = new_roster
    end

    def connect!
      raise ConnectionError, "Connections are disabled - use Jabber::Simple::force_connect() to reconnect." if @disconnected
      # Pre-connect
      @connect_mutex ||= Mutex.new
      @connect_mutex.lock
      disconnect!(false) if connected?

      # Connect
      jid = JID.new(@jid)
      my_client = Client.new(@jid)
      my_client.connect
      my_client.auth(@password)
      self.client = my_client

      # Post-connect
      register_default_callbacks
      status(@presence, @status_message)
      @connect_mutex.unlock
    end

    def disconnect!(auto_reconnect = true)
      if client.respond_to?(:is_connected?) && client.is_connected?
        client.close
      end
      client = nil
      @disconnected = auto_reconnect
    end

    def register_default_callbacks
      client.add_message_callback do |message|
        queue(:received_messages) << message unless message.body.nil?
      end

      roster.add_subscription_callback do |roster_item, presence|
        if presence.type == :subscribed
          queue(:new_subscriptions) << [roster_item, presence]
        end
      end

      roster.add_subscription_request_callback do |roster_item, presence|
        if accept_subscriptions?
          roster.accept_subscription(presence.from) 
        else
          queue(:subscription_requests) << [roster_item, presence]
        end
      end

      @presence_updates = {}
      @presence_mutex = Mutex.new
      roster.add_presence_callback do |roster_item, old_presence, new_presence|
        simple_jid = roster_item.jid.strip.to_s
        presence = case new_presence.type
                   when nil: new_presence.show || :online
                   when :unavailable: :unavailable
                   else
                     nil
                   end

        if presence && @presence_updates[simple_jid] != presence
          queue(:presence_updates) << simple_jid
          @presence_mutex.synchronize { @presence_updates[simple_jid] = [presence, new_presence.status] }
        end
      end
    end

    # This thread facilitates the delivery of messages to users who haven't yet
    # accepted an invitation from us. When we attempt to deliver a message, if
    # the user hasn't subscribed, we place the message in a queue for later
    # delivery. Once a user has accepted our authorization request, we deliver
    # any messages that have been queued up in the meantime.
    def start_deferred_delivery_thread #:nodoc:
      Thread.new {
        loop {
          messages = [queue(:pending_messages).pop].flatten
          messages.each do |message|
            if subscribed_to?(message[:to])
              deliver(message[:to], message[:message], message[:type])
            else
              queue(:pending_messages) << message
            end
          end
        }
      }
    end

    def queue(queue)
      @queues ||= Hash.new { |h,k| h[k] = Queue.new }
      @queues[queue]
    end

    def dequeue(queue, non_blocking = true, max_items = 100, &block)
      queue_items = []
      max_items.times do
        queue_item = queue(queue).pop(non_blocking) rescue nil
        break if queue_item.nil?
        queue_items << queue_item
        yield queue_item if block_given?
      end
      queue_items
    end
  end
end

true
