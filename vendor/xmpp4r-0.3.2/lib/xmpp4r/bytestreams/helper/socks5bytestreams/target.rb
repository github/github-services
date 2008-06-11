# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

module Jabber
  module Bytestreams
    ##
    # SOCKS5 Bytestreams implementation of the target site
    class SOCKS5BytestreamsTarget < SOCKS5Bytestreams
      ##
      # Wait until the stream has been established
      #
      # May raise various exceptions
      def accept
        error = nil
        connect_sem = Semaphore.new

        @stream.add_iq_callback(200, self) { |iq|
          if iq.type == :set and iq.from == @initiator_jid and iq.to == @target_jid and iq.query.kind_of?(IqQueryBytestreams)
            begin
              @stream.delete_iq_callback(self)

              iq.query.each_element('streamhost') { |streamhost|
                if streamhost.host and streamhost.port and not @socks
                  begin
                    @socks = connect_socks(streamhost)
                    @streamhost_used = streamhost
                  rescue Exception => e
                    Jabber::debuglog("SOCKS5 Bytestreams: #{e.class}: #{e}\n#{e.backtrace.join("\n")}")
                    @streamhost_cbs.process(streamhost, :failure, e)
                  end
                end
              }

              reply = iq.answer(false)
              if @streamhost_used
                reply.type = :result
                reply.add(IqQueryBytestreams.new)
                reply.query.add(StreamHostUsed.new(@streamhost_used.jid))
              else
                reply.type = :error
                reply.add(Error.new('item-not-found'))
              end
              @stream.send(reply)
            rescue Exception => e
              error = e
            end
              
            connect_sem.run
            true
          else
            false
          end
        }

        connect_sem.wait
        raise error if error
        (@socks != nil)
      end
    end
  end
end

