#
# parser test
#

require 'tmail'

puts "testing parser --------------------------------"
puts

TMail::Mail.load( 'data/normal' ).each_header do |key, field|
  if field.respond_to? :parse, true then
    field.instance_eval {
      parse
      @written = true
    }
  end
  printf "%s ok\n", field.name
  # puts field.decoded
end
