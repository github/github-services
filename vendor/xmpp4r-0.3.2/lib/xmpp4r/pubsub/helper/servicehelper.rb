# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/
#
# It's recommented to read the XEP-0066 before you use this Helper.
# 

require 'xmpp4r/pubsub/iq/pubsub'
require 'xmpp4r/pubsub/stanzas/event'
require 'xmpp4r/pubsub/stanzas/item'
require 'xmpp4r/pubsub/stanzas/items'
require 'xmpp4r/pubsub/stanzas/subscription'
require 'xmpp4r/dataforms'

module Jabber
  module PubSub
    ##
    # A Helper representing a PubSub Service
    class ServiceHelper

      ##
      # Creates a new representation of a pubsub service
      # client:: [Jabber::Stream]
      # pubsubjid:: [String] or [Jabber::JID]
      def initialize(client, pubsubjid)
        @client = client
        @pubsubjid = pubsubjid
        @event_cbs = CallbackList.new
        @client.add_message_callback(200,self) { |message|
          handle_message(message)
        }
      end

      ##
      # Create a new node on the pubsub service
      # node:: [String] you node name - otherwise you get a automaticly generated one (in most cases)
      # configure:: [Jabber::XMLStanza] if you want to configure you node (default nil)
      # return:: [String]
      def create(node=nil, configure=nil)
        rnode = nil
        iq = basic_pubsub_query(:set)
        iq.pubsub.add(REXML::Element.new('create')).attributes['node'] = node
        if configure
          confele =  REXML::Element.new('configure')

          if configure.type_of?(XMLStanza)
            confele << configure
          end
          iq.pubsub.add(confele)
        end

        @client.send_with_id(iq) do |reply|
          if (create = reply.first_element('pubsub/create'))
            rnode = create.attributes['node']
          end
          true
        end

        rnode
      end

      ##
      # Delete a pubsub node
      # node:: [String]
      # return:: true
      def delete(node)
        iq = basic_pubsub_query(:set,true)
        iq.pubsub.add(REXML::Element.new('delete')).attributes['node'] = node
        @client.send_with_id(iq) { |reply|
          true
        }
      end

      ##
      # NOTE: this method sends only one item per publish request because some services may not
      # allow batch processing
      # maybe this will changed in the future
      # node:: [String]
      # item:: [Jabber::PubSub::Item]
      # return:: true
      def publish(node,item)
        iq = basic_pubsub_query(:set)
        publish = iq.pubsub.add(REXML::Element.new('publish'))
        publish.attributes['node'] = node
        if item.kind_of?(Jabber::PubSub::Item)
          publish.add(item)
          @client.send_with_id(iq) { |reply| true }
        end
      end

      ##
      # node:: [String]
      # item:: [REXML::Element]
      # id:: [String]
      # return:: true
      def publish_with_id(node,item,id)
        if item.kind_of?(REXML::Element)
          xmlitem = Jabber::PubSub::Item.new
          xmlitem.id = id
          xmlitem.add(item)
          publish(node,xmlitem)
        else
          raise "given item is not a proper xml document or Jabber::PubSub::Item"
        end
      end

      ##
      # gets all items from a pubsub node
      # node:: [String]
      # count:: [Fixnum]
      # return:: [Hash] { id => [Jabber::PubSub::Item] }
      def items(node,count=nil)
        iq = basic_pubsub_query(:get)
        items = Jabber::PubSub::Items.new
        items.node = node
        iq.pubsub.add(items)
        res = nil
        @client.send_with_id(iq) { |reply|
          if reply.kind_of?(Iq) and reply.pubsub and reply.pubsub.first_element('items')
            res = {}
            reply.pubsub.first_element('items').each_element('item') do |item|
              res[item.attributes['id']] = item.children.first if item.children.first
            end
          end
          true
        }
        res
      end

      ##
      # shows the affiliations on a pubsub service
      # return:: [Hash] of { node => symbol }
      def affiliations
        iq = basic_pubsub_query(:get)
        iq.pubsub.add(REXML::Element.new('affiliations'))
        res = nil
        @client.send_with_id(iq) { |reply|
          if reply.pubsub.first_element('affiliations')
            res = {}
            reply.pubsub.first_element('affiliations').each_element('affiliation') do |affiliation|
              # TODO: This should be handled by an affiliation element class
              aff = case affiliation.attributes['affiliation']
                      when 'owner' then :owner
                      when 'publisher' then :publisher
                      when 'none' then :none
                      when 'outcast' then :outcast
                      else nil
                    end
              res[affiliation.attributes['node']] = aff
            end
          end
          true
        }
        res
      end

      ##
      # shows all subscriptions on the given node
      # node:: [String], or nil for all
      # return:: [Array] of [REXML::Element]
      def subscriptions(node=nil)
        iq = basic_pubsub_query(:get)
        entities = iq.pubsub.add(REXML::Element.new('subscriptions'))
        entities.attributes['node'] = node
        res = nil
        @client.send_with_id(iq) { |reply|
          if reply.pubsub.first_element('subscriptions')
            res = []
            reply.pubsub.first_element('subscriptions').each_element('subscription') { |subscription|
              res << REXML::Element.new(subscription)
            }
          end
          true
        }
        res
      end

      ##
      # shows all jids of subscribers of a node
      # node:: [String]
      # return:: [Array] of [String]
      def subscribers(node)
        res = []
        subscriptions(node).each { |sub|
          res << sub.attributes['jid']
        }
        res
      end

      ##
      # subscribe to a node
      # node:: [String]
      # return:: [Hash] of { attributename => value }
      def subscribe(node)
        iq = basic_pubsub_query(:set)
        sub = REXML::Element.new('subscribe')
        sub.attributes['node'] = node
        sub.attributes['jid'] = @client.jid.strip
        iq.pubsub.add(sub)
        res = {}
        @client.send_with_id(iq) do |reply|
          pubsubanswer = reply.pubsub
          if pubsubanswer.first_element('subscription')
            pubsubanswer.each_element('subscription') { |element|
              element.attributes.each { |name,value| res[name] = value }
            }
          end
          true
        end # @client.send_with_id(iq)
        res
      end

      ##
      # Unsubscibe from a node with an optional subscription id
      #
      # May raise ErrorException
      # node:: [String]
      # subid:: [String] or nil
      # return:: true
      def unsubscribe(node,subid=nil)
        iq = basic_pubsub_query(:set)
        unsub = REXML::Element.new('unsubscribe')
        unsub.attributes['node'] = node
        unsub.attributes['jid'] = @client.jid.strip
        unsub.attributes['subid'] = subid
        iq.pubsub.add(unsub)
        @client.send_with_id(iq) { |reply| true        } # @client.send_with_id(iq)
      end

      ##
      # get options of a node
      # node:: [String]
      # subid:: [String] or nil
      # return:: [Jabber::XData]
      def get_options(node,subid=nil)
        iq = basic_pubsub_query(:get)
        opt = REXML::Element.new('options')
        opt.attributes['node'] = node
        opt.attributes['jid'] = @client.jid.strip
        opt.attributes['subid'] = subid
        iq.pubsub.add(opt)
        ret = nil
        @client.send_with_id(iq) { |reply|
          reply.pubsub.options.first_element('x') { |xdata|
    
            ret = xdata if xdata.kind_of?(Jabber::XData)
    
          }
        true
        }
        return ret
      end

      ##
      # set options for a node
      # node:: [String]
      # options:: [Jabber::XData]
      # subid:: [String] or nil
      # return:: true 
      def set_options(node,options,subid=nil)
        iq = basic_pubsub_query(:set)
        opt = REXML::Element.new('options')
        opt.attributes['node'] = node
        opt.attributes['jid'] = @client.jid.strip
        opt.attributes['subid'] = subid
        iq.pubsub.add(opt)
        iq.pubsub.options.add(options)
        @client.send_with_id(iq) { |reply| true }
      end
      
      ##
      # purges all items on a persist node
      # node:: [String]
      # return:: true
      def purge(node)
        iq = basic_pubsub_query(:set)
	purge = REXML::Element.new('purge')
	purge.attributes['node'] = node
	iq.pubsub.add(purge)
	@client.send_with_id(iq) { |reply| true }
      end

      ##
      # String representation
      # result:: [String] The PubSub service's JID
      def to_s
        @pubsubjid.to_s
      end

      ##
      # Register callbacks for incoming events
      # (i.e. Message stanzas containing) PubSub notifications
      def add_event_callback(prio = 200, ref = nil, &block)
        @event_cbs.add(prio, ref, block)
      end

      private

      ##
      # creates a basic pubsub iq
      # basic_pubsub_query(type)
      # type:: [Symbol]
      def basic_pubsub_query(type,ownerusecase = false)
        iq = Jabber::Iq::new(type,@pubsubjid)
	if ownerusecase 
	  iq.add(IqPubSubOwner.new)
	else
          iq.add(IqPubSub.new)
	end
        iq
      end

      ##
      # handling incoming events
      # handle_message(message)
      # message:: [Jabber::Message]
      def handle_message(message)
        if message.from == @pubsubjid and message.first_element('event').kind_of?(Jabber::PubSub::Event)
          event = message.first_element('event')
          @event_cbs.process(event)
        end
      end

    end
  end
end
