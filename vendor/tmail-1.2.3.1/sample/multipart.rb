#
# MIME multipart parsing test
#

require 'tmail'

mail = TMail::Mail.load( ARGV[0] || 'data/multipart' )

puts '========= preamble =============='
puts mail.body
puts

puts '========== parts ================'
mail.parts.each_with_index do |i,idx|
  puts "<#{idx+1}>"
  puts i
  puts
end

puts '========= epilogue =============='
puts mail.epilogue
puts

puts "========= re-struct ============="
puts mail.decoded
puts
