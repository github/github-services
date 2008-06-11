#
# checking mail From: header
#

require 'tmail'

unless ARGV[0] then
  $stderr.puts "usage: ruby fromcheck.rb <mhdir>"
  exit 1
end

table = {}    # from-addr-spec => [count, friendly-from]
ld = TMail::MhLoader.new( ARGV[0] )
ld.each_port do |port|
  mail = TMail::Mail.new( port )
  addr, = mail.from_addrs
  if addr then
    (table[addr.spec] ||= [0, mail.friendly_from])[0] += 1
  end
end

table.to_a.sort {|a,b|
    b[1][0] <=> a[1][0]
}.each_with_index do |(spec,(n,from)), i|
  printf "%3d %-33s %d\n", i+1, from, n
end
