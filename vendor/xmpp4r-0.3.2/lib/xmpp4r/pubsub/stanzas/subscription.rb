# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module PubSub
    ##
    # Subscription
    class Subscription < XMPPElement
      name_xmlns 'subscription', NS_PUBSUB
      def initialize(myjid=nil,mynode=nil,mysubid=nil,mysubscription=nil)
        super(true)
        jid = myjid
	node =  mynode
	subid =  mysubid
	state = mysubscription
      end
      def jid
        attributes['jid']
      end
      def jid=(myjid)
        attributes['jid'] = myjid
      end
      
      def node
        attributes['node']
      end
      def node=(mynode)
        attributes['node'] = mynode
      end
      
      def subid
        attributes['subid']
      end
      def subid=(mysubid)
        attributes['subid'] = mysubid
      end
       
      def state                                                                                                            
          # each child of event
          # this should interate only one time
          case attributes['subscription']
              when 'none'      		then return :none
              when 'pending'   		then return :pending
              when 'subscribed'         then return :subscribed
              when 'unconfigured'       then return :items
              else return nil
          end
      end
      def state=(mystate)
        attributes['subscription'] = mystate
      end
      alias subscription state
    end
  end
end