# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

##
# The Jabber module is the root namespace of the library. You might want
# to Include it in your script to ease your coding. It provides
# a simple debug logging support.
module Jabber
  # XMPP4R Version number
  XMPP4R_VERSION = '0.3.2'
end

require 'xmpp4r/client'
require 'xmpp4r/component'
require 'xmpp4r/debuglog'
