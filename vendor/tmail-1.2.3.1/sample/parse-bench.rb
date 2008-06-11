#
# parser benchmark
#

require 'tmail'


if ARGV.empty? then
  $stderr.puts "usage: #{$0} <mhdir> <mhdir>..."
  exit 0
end
ARGV.each do |dname|
  unless File.directory? dname then
    $stderr.puts "not directory: #{dname}"
    exit 1
  end
end

$stdout.sync = true

$count   = 0
$failnum = 0
$dirfail = 0
$fieldname = ''
$dirname   = ''
$port  = nil

begin
  ARGV.each do |dirname|
    $dirname = dirname

    TMail::MhLoader.new( dirname ).each do |port|
      begin
        t = TMail::Mail.new( port )
        $port = port

        t.each_header do |key, field|
          $fieldname = key
          next if /received/i === key
          if ::TMail::StructH === field then
            field.instance_eval { parse unless @parsed }
          end
        end
      rescue TMail::SyntaxError
        $stderr.puts "fail in #{$count+1}, field #{$fieldname}"
        $stderr.puts $!.to_s
        $failnum += 1
        $dirfail += 1

        if $failnum % 10 == 0 then
          puts 'fail = ' + $failnum.to_s
          #raise
        end
      end

      $count += 1
      puts "end #{$count}" if $count % 50 == 0
    end

    puts "directory #{dirname} end, fail=#{$dirfail}"
    $dirfail = 0
  end
rescue
  puts "at #{$port.inspect}, non ParseError raised"
  raise
end

puts "parse #{$count} files, fail=#{$failnum}"
