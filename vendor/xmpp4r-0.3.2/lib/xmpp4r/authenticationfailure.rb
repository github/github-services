# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

module Jabber
  ##
  # The AuthenticationFailure is an Exception to be raised
  # when Client or Component authentication fails
  #
  # There are no special arguments
  class AuthenticationFailure < RuntimeError
  end
end
