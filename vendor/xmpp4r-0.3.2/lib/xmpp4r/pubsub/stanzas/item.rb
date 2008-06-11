# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module PubSub
    ##
    # Item
    # One PubSub Item
    class Item < XMPPElement
      name_xmlns 'item', NS_PUBSUB
      force_xmlns true
      def initialize(id=nil)
        super()
        attributes['id'] = id
      end
      def id
        attributes['id']
      end
      def id=(myid)
        attributes['id'] = myid
      end
    end
  end
end
