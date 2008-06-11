# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/discovery'

module Jabber
  module PubSub
    class NodeBrowser
      ##
      # Initialize a new NodeBrowser
      # new(stream,pubsubservice)
      # stream:: [Jabber::Stream]
      def initialize(stream)
        @stream = stream
      end

      ##
      # Retrive the nodes
      # Throws an ErrorException when receiving
      # <tt><iq type='error'/></tt>
      # jid:: [JID] Target entity (set only domain!)
      # return:: [Array] of [String] or [nil]
      def nodes(jid)
        iq = Iq.new(:get,jid)
        iq.from = @stream.jid
        iq.add(Discovery::IqQueryDiscoItems.new)
        nodes = []
        err = nil
        @stream.send_with_id(iq) { |answer|
          if answer.type == :result
            answer.query.each_element('item') { |item|
              nodes.push(item.node)
            }
            true
          elsif answer.type == :error
            err = answer.error
            true
          else
            false
          end
        }
        return nodes
      end

      ##
      # Retrive the nodes with names
      # Throws an ErrorExeption when reciving
      # <tt><iq type='error'/></tt>
      # jid:: [Jabber::JID] Target entity (set only domain!)
      # return:: [Array] of [Hash] with keys 'node' => [String] and 'name' => [String] or [nil]
      def nodes_names(jid)
        iq = Iq.new(:get,jid)
        iq.from = @stream.jid
        iq.add(Discovery::IqQueryDiscoItems.new)
        nodes = []
        err = nil
        @stream.send_with_id(iq) { |answer|
          if answer.type == :result
            answer.query.each_element('item') { |item|
              nodes.push( {'node' => item.node,'name' => item.iname } )
            }
            true
          elsif answer.type == :error
            err = answer.error
            true
          else
            false
          end
        }
        return nodes
      end


      ##
      # Retrive the items from a node
      # Throws an ErrorExeption when reciving
      # <tt><iq type='error'/></tt>
      # jid:: [Jabber::JID] Target entity (set only domain!)
      # node:: [String]
      # return:: [Array] of [Hash] with keys 'name' => [String] and 'jid' => [Jabber::JID]
      def items(jid,node)
        iq = Iq.new(:get,jid)
        iq.from = @stream.jid
	discoitems = Discovery::IqQueryDiscoItems.new
	discoitems.node = node
        iq.add(discoitems)
        items = []
        err = nil
        @stream.send_with_id(iq) { |answer|
          if answer.type == :result
            answer.query.each_element('item') { |item|
              items.push( {'jid' => item.jid,'name' => item.iname } )
            }
            true
          elsif answer.type == :error
            err = answer.error
            true
          else
            false
          end
        }
        return items
      end

      ##
      # get disco info for a node
      # jid:: [Jabber::JID]
      # node:: [String]
      # return:: [Hash] with possible keys type:: [String] ,category:: [String],features:: [Array] of feature, nodeinformation:: [Jabber::XData]
      # check http://www.xmpp.org/extensions/xep-0060.html#entity for more infos
      
      # this is only for a xep <-> nodebrowser.rb understanding
      alias get_metadata get_info
      
      def get_info(jid,node)
        iq = Iq.new(:get,jid)
	iq.from = @stream.jid
	discoinfo = Discovery::IqQueryDiscoInfo.new
	discoinfo.node = node
	iq.add(discoinfo)
	info = {}
	@stream.send_with_id(iq) { |answer|
	  if answer.type == :result
	    
	    identity = answer.query.identity
	    info['type'] = identity.type
	    info['category'] = identity.category
	    
	    info['features'] = answer.query.features
	    
# i think its not needed - if you think so then delete it	    
#	    answer.query.each_element('identity') { |identity|
#	      info['type'] = identity.type
#	      info['category'] = identity.category
#	    }
#	    
#	    features = []
#	    answer.query.each_element('feature') { |feature|
#	     features.push(feature)
#	    }
#	    info['features'] = features
#	    
	    answer.query.each_element('x') { |x|
	      info['nodeinformation'] = x 
	    }
	  end
	}
	return info
      end
      
      ##
      # get type of node
      # jid:: [Jabber::JID]
      # node:: [String]
      # 
      def type(jid,node)
        info = get_info(jid,node)
	return info['type']
      end
      
      ##
      # get category of node
      # jid:: [Jabber::JID]
      # node:: [String]
      # 
      def category(jid,node)
        info = get_info(jid,node)
	return info['category']
      end

    end #class
  end #module
end #module
