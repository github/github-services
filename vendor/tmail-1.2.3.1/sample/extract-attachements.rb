#
# extract-attachments.rb  -- Extracts attachment(s) from the message.
#
# Usage: ruby extract-attachments.rb mail mail...
#

require 'tmail'

def main
  idx = 1
  ARGV.each do |fname|
    TMail::Mail.load(fname).parts.each do |m|
      m.base64_decode
      File.open("#{idx}.#{ext(m)}", 'w') {|f|
        f.write m.body
      }
      idx += 1
    end
  end
end

CTYPE_TO_EXT = {
  'image/jpeg' => 'jpeg',
  'image/gif'  => 'gif',
  'image/png'  => 'png',
  'image/tiff' => 'tiff'
}

def ext( mail )
  CTYPE_TO_EXT[mail.content_type] || 'txt'
end

main
