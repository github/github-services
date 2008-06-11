require 'test_helper'
require 'tmail'

class TestAttachments < Test::Unit::TestCase

  def test_attachment
    mail = TMail::Mail.new
    mail.mime_version = "1.0"
    mail.set_content_type 'multipart', 'mixed', {'boundary' => 'Apple-Mail-13-196941151'}
    mail.body =<<HERE
--Apple-Mail-13-196941151
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain;
	charset=ISO-8859-1;
	delsp=yes;
	format=flowed

This is the first part.

--Apple-Mail-13-196941151
Content-Type: text/x-ruby-script; name="hello.rb"
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment;
	filename="api.rb"

puts "Hello, world!"
gets

--Apple-Mail-13-196941151--
HERE
    assert_equal(true, mail.multipart?)
    assert_equal(1, mail.attachments.length)
  end
  
  def test_recursive_multipart_processing
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email7")
    mail = TMail::Mail.parse(fixture)
    assert_equal "This is the first part.\n\nAttachment: test.rb\nAttachment: test.pdf\n\n\nAttachment: smime.p7s\n", mail.body
  end

  def test_decode_encoded_attachment_filename
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email8")
    mail = TMail::Mail.parse(fixture)
    attachment = mail.attachments.last
    assert_equal "01 Quien Te Dij\212at. Pitbull.mp3", attachment.original_filename
  end
  
end
