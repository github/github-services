#
# sendmail.rb
#

require 'tmail'
require 'net/smtp'
require 'nkf'
require 'etc'
require 'socket'
require 'getopts'


def usage( status, msg = nil )
  output = (status == 0 ? $stdout : $stderr)
  output.puts msg if msg
  output.print(<<EOS)
Usage: cat msg | #{File.basename $0} [-j|--ja] [-s <subject>] [-f <from>] <to>

  -h,--host=addr     SMTP server address. (default=localhost)
  -s,--subject=sbj   subject of the message. (default=(none))
  -f,--from=from     from address.
  -j,--ja            handle japanese message. (default=off)

EOS
  exit status
end

def main
  getopts('j', 'ja', 'h:', 'host:',
          's:', 'subject:', 'f:', 'from:',
          'help') or usage(1)

  smtphost = $OPT_host || $OPT_h || 'localhost'
  subject = $OPT_subject || $OPT_s
  from = $OPT_from || $OPT_f || guess_from_address()
  usage(1, 'Sender address not given')  unless from
  to = ARGV
  usage(1, 'Receipt address(es) not given') if to.empty?
  ja_locale = $OPT_ja || $OPT_j

  send_mail smtphost, setup_mail(from, to, subject, $stdin.read, ja_locale)
end

def setup_mail( from, to, subject, body, ja_locale )
  mail = TMail::Mail.new
  mail.date = Time.now
  mail.from = from
  mail.to = to
  mail.subject = subject if subject
  mail.mime_version = '1.0'
  if ja_locale
    mail.body = NKF.nkf('-j', body)
    mail.set_content_type 'text', 'plain', 'charset' => 'iso-2022-jp'
  else
    mail.body = body
    mail.set_content_type 'text', 'plain'
  end
  mail
end

def send_mail( host, mail )
  msg = mail.encoded
  $stderr.print msg if $DEBUG

  smtp = Net::SMTP.new(host, 25)
  smtp.set_debug_output $stderr if $DEBUG
  smtp.start {
    smtp.send_mail msg, mail.from_address, mail.destinations
  }
end

def guess_from_address
  user = getlogin()
  unless user
    $stderr.puts 'cannot get user account; abort.'
    exit 1
  end
  if domain = (Socket.gethostname || ENV['HOSTNAME'] || ENV['HOST'])
    user + '@' + domain
  else
    user
  end
end

def getlogin
  begin
    require 'etc'
    Etc.getlogin
  rescue LoadError
    ENV['LOGNAME'] || ENV['USER']
  end
end

main
