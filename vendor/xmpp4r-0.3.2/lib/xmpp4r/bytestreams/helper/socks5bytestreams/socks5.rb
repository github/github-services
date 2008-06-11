# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'socket'

module Jabber
  module Bytestreams
    ##
    # Can be thrown upon communication error with
    # a SOCKS5 proxy
    class SOCKS5Error < RuntimeError; end

    ##
    # A SOCKS5 client implementation
    #
    # ==Usage:
    # * Initialize with proxy's address and port
    # * Authenticate
    # * Connect to target host
    class SOCKS5Socket < TCPSocket
      ##
      # Connect to SOCKS5 proxy
      def initialize(socks_host, socks_port)
        super(socks_host, socks_port)
      end

      ##
      # Authenticate for SOCKS5 proxy
      #
      # Currently supports only 'no authentication required'
      def auth
        write("\x05\x01\x00")
        buf = read(2)
        if buf.nil? or buf != "\x05\x00"
          close
          raise SOCKS5Error.new("Invalid SOCKS5 authentication: #{buf.inspect}")
        end

        self
      end

      ##
      # Issue a CONNECT request to a host name
      # which is to be resolved by the proxy.
      # domain:: [String] Host name
      # port:: [Fixnum] Port number
      def connect_domain(domain, port)
        write("\x05\x01\x00\x03#{domain.size.chr}#{domain}#{[port].pack("n")}")
        buf = read(7 + domain.size)
        if buf.nil? or buf[0..1] != "\005\000"
          close
          raise SOCKS5Error.new("Invalid SOCKS5 connect: #{buf.inspect}")
        end

        self
      end
    end
  end
end
