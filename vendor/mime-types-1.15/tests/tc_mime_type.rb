#! /usr/bin/env ruby
#--
# MIME::Types for Ruby
#   http://rubyforge.org/projects/mime-types/
#   Copyright 2003 - 2005 Austin Ziegler.
#   Licensed under a MIT-style licence.
#
# $Id: tc_mime_type.rb,v 1.2 2006/02/12 21:27:22 austin Exp $
#++
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'mime/types'
require 'test/unit'

class Test_MIME__Type < Test::Unit::TestCase #:nodoc:
  def setup
    @zip = MIME::Type.new('x-appl/x-zip') { |t| t.extensions = ['zip', 'zp'] }
  end

  def test_CMP # '<=>'
    assert(MIME::Type.new('text/plain') == MIME::Type.new('text/plain'))
    assert(MIME::Type.new('text/plain') != MIME::Type.new('image/jpeg'))
    assert(MIME::Type.new('text/plain') == 'text/plain')
    assert(MIME::Type.new('text/plain') != 'image/jpeg')
    assert(MIME::Type.new('text/plain') > MIME::Type.new('text/html'))
    assert(MIME::Type.new('text/plain') > 'text/html')
    assert(MIME::Type.new('text/html') < MIME::Type.new('text/plain'))
    assert(MIME::Type.new('text/html') < 'text/plain')
    assert('text/html' == MIME::Type.new('text/html'))
    assert('text/html' < MIME::Type.new('text/plain'))
    assert('text/plain' > MIME::Type.new('text/html'))
  end

  def test_ascii?
    assert(MIME::Type.new('text/plain').ascii?)
    assert(!MIME::Type.new('image/jpeg').ascii?)
    assert(!MIME::Type.new('application/x-msword').ascii?)
    assert(MIME::Type.new('text/vCard').ascii?)
    assert(!MIME::Type.new('application/pkcs7-mime').ascii?)
    assert(!@zip.ascii?)
  end

  def test_binary?
    assert(!MIME::Type.new('text/plain').binary?)
    assert(MIME::Type.new('image/jpeg').binary?)
    assert(MIME::Type.new('application/x-msword').binary?)
    assert(!MIME::Type.new('text/vCard').binary?)
    assert(MIME::Type.new('application/pkcs7-mime').binary?)
    assert(@zip.binary?)
  end

  def test_complete?
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'linux')
    end
    assert(@yaml.complete?)
    assert_nothing_raised { @yaml.extensions = nil }
    assert(!@yaml.complete?)
  end

  def test_content_type
    assert_equal(MIME::Type.new('text/plain').content_type, 'text/plain')
    assert_equal(MIME::Type.new('image/jpeg').content_type, 'image/jpeg')
    assert_equal(MIME::Type.new('application/x-msword').content_type, 'application/x-msword')
    assert_equal(MIME::Type.new('text/vCard').content_type, 'text/vCard')
    assert_equal(MIME::Type.new('application/pkcs7-mime').content_type, 'application/pkcs7-mime')
    assert_equal(@zip.content_type, 'x-appl/x-zip');
  end

  def test_encoding
    assert_equal(MIME::Type.new('text/plain').encoding, 'quoted-printable')
    assert_equal(MIME::Type.new('image/jpeg').encoding, 'base64')
    assert_equal(MIME::Type.new('application/x-msword').encoding, 'base64')
    assert_equal(MIME::Type.new('text/vCard').encoding, 'quoted-printable')
    assert_equal(MIME::Type.new('application/pkcs7-mime').encoding, 'base64')
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'linux')
    end
    assert_equal(@yaml.encoding, '8bit')
    assert_nothing_raised { @yaml.encoding = 'base64' }
    assert_equal(@yaml.encoding, 'base64')
    assert_nothing_raised { @yaml.encoding = :default }
    assert_equal(@yaml.encoding, 'quoted-printable')
    assert_raises(ArgumentError) { @yaml.encoding = 'binary' }
    assert_equal(@zip.encoding, 'base64')
  end

  def test_eql?
    assert(MIME::Type.new('text/plain').eql?(MIME::Type.new('text/plain')))
    assert(!MIME::Type.new('text/plain').eql?(MIME::Type.new('image/jpeg')))
    assert(!MIME::Type.new('text/plain').eql?('text/plain'))
    assert(!MIME::Type.new('text/plain').eql?('image/jpeg'))
  end

  def test_extensions
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'linux')
    end
    assert_equal(@yaml.extensions, ['yaml', 'yml'])
    assert_nothing_raised { @yaml.extensions = 'yaml' }
    assert_equal(@yaml.extensions, ['yaml'])
    assert_equal(@zip.extensions.size, 2)
    assert_equal(@zip.extensions, ['zip', 'zp'])
  end

  def test_like?
    assert(MIME::Type.new('text/plain').like?(MIME::Type.new('text/plain')))
    assert(MIME::Type.new('text/plain').like?(MIME::Type.new('text/x-plain')))
    assert(!MIME::Type.new('text/plain').like?(MIME::Type.new('image/jpeg')))
    assert(MIME::Type.new('text/plain').like?('text/plain'))
    assert(MIME::Type.new('text/plain').like?('text/x-plain'))
    assert(!MIME::Type.new('text/plain').like?('image/jpeg'))
  end

  def test_media_type
    assert_equal(MIME::Type.new('text/plain').media_type, 'text')
    assert_equal(MIME::Type.new('image/jpeg').media_type, 'image')
    assert_equal(MIME::Type.new('application/x-msword').media_type, 'application')
    assert_equal(MIME::Type.new('text/vCard').media_type, 'text')
    assert_equal(MIME::Type.new('application/pkcs7-mime').media_type, 'application')
    assert_equal(MIME::Type.new('x-chemical/x-pdb').media_type, 'chemical')
    assert_equal(@zip.media_type, 'appl')
  end

  def test_platform?
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'oddbox')
    end
    assert(!@yaml.platform?)
    assert_nothing_raised { @yaml.system = nil }
    assert(!@yaml.platform?)
    assert_nothing_raised { @yaml.system = /#{RUBY_PLATFORM}/ }
    assert(@yaml.platform?)
  end

  def test_raw_media_type
    assert_equal(MIME::Type.new('text/plain').raw_media_type, 'text')
    assert_equal(MIME::Type.new('image/jpeg').raw_media_type, 'image')
    assert_equal(MIME::Type.new('application/x-msword').raw_media_type, 'application')
    assert_equal(MIME::Type.new('text/vCard').raw_media_type, 'text')
    assert_equal(MIME::Type.new('application/pkcs7-mime').raw_media_type, 'application')

    assert_equal(MIME::Type.new('x-chemical/x-pdb').raw_media_type, 'x-chemical')
    assert_equal(@zip.raw_media_type, 'x-appl')
  end

  def test_raw_sub_type
    assert_equal(MIME::Type.new('text/plain').raw_sub_type, 'plain')
    assert_equal(MIME::Type.new('image/jpeg').raw_sub_type, 'jpeg')
    assert_equal(MIME::Type.new('application/x-msword').raw_sub_type, 'x-msword')
    assert_equal(MIME::Type.new('text/vCard').raw_sub_type, 'vCard')
    assert_equal(MIME::Type.new('application/pkcs7-mime').raw_sub_type, 'pkcs7-mime')
    assert_equal(@zip.raw_sub_type, 'x-zip')
  end

  def test_registered?
    assert(MIME::Type.new('text/plain').registered?)
    assert(MIME::Type.new('image/jpeg').registered?)
    assert(!MIME::Type.new('application/x-msword').registered?)
    assert(MIME::Type.new('text/vCard').registered?)
    assert(MIME::Type.new('application/pkcs7-mime').registered?)
    assert(!@zip.registered?)
  end

  def test_signature?
    assert(!MIME::Type.new('text/plain').signature?)
    assert(!MIME::Type.new('image/jpeg').signature?)
    assert(!MIME::Type.new('application/x-msword').signature?)
    assert(MIME::Type.new('text/vCard').signature?)
    assert(MIME::Type.new('application/pkcs7-mime').signature?)
  end

  def test_simplified
    assert_equal(MIME::Type.new('text/plain').simplified, 'text/plain')
    assert_equal(MIME::Type.new('image/jpeg').simplified, 'image/jpeg')
    assert_equal(MIME::Type.new('application/x-msword').simplified, 'application/msword')
    assert_equal(MIME::Type.new('text/vCard').simplified, 'text/vcard')
    assert_equal(MIME::Type.new('application/pkcs7-mime').simplified, 'application/pkcs7-mime')
    assert_equal(MIME::Type.new('x-chemical/x-pdb').simplified, 'chemical/pdb')
  end

  def test_sub_type
    assert_equal(MIME::Type.new('text/plain').sub_type, 'plain')
    assert_equal(MIME::Type.new('image/jpeg').sub_type, 'jpeg')
    assert_equal(MIME::Type.new('application/x-msword').sub_type, 'msword')
    assert_equal(MIME::Type.new('text/vCard').sub_type, 'vcard')
    assert_equal(MIME::Type.new('application/pkcs7-mime').sub_type, 'pkcs7-mime')
    assert_equal(@zip.sub_type, 'zip')
  end

  def test_system
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'linux')
    end
    assert_equal(@yaml.system, %r{linux})
    assert_nothing_raised { @yaml.system = /win32/ }
    assert_equal(@yaml.system, %r{win32})
    assert_nothing_raised { @yaml.system = nil }
    assert_nil(@yaml.system)
  end

  def test_system?
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'linux')
    end
    assert(@yaml.system?)
    assert_nothing_raised { @yaml.system = nil }
    assert(!@yaml.system?)
  end

  def test_to_a
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'linux')
    end
    assert_equal(@yaml.to_a, ['text/x-yaml', ['yaml', 'yml'], '8bit',
                 /linux/, nil, nil, nil, false])
  end

  def test_to_hash
    assert_nothing_raised do
      @yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                    'linux')
    end
    assert_equal(@yaml.to_hash,
                  { 'Content-Type' => 'text/x-yaml',
                    'Content-Transfer-Encoding' => '8bit',
                    'Extensions' => ['yaml', 'yml'],
                    'System' => /linux/,
                    'Registered' => false,
                    'URL' => nil,
                    'Obsolete' => nil,
                    'Docs' => nil })
  end

  def test_to_s
    assert_equal("#{MIME::Type.new('text/plain')}", 'text/plain')
  end

  def test_s_constructors
    assert_not_nil(@zip)
    yaml = MIME::Type.from_array('text/x-yaml', ['yaml', 'yml'], '8bit',
                                  'linux')
    assert_instance_of(MIME::Type, yaml)
    yaml = MIME::Type.from_hash('Content-Type' => 'text/x-yaml',
                                'Content-Transfer-Encoding' => '8bit',
                                'System' => 'linux',
                                'Extensions' => ['yaml', 'yml'])
    assert_instance_of(MIME::Type, yaml)
    yaml = MIME::Type.new('text/x-yaml') do |y|
      y.extensions = ['yaml', 'yml']
      y.encoding = '8bit'
      y.system = 'linux'
    end
    assert_instance_of(MIME::Type, yaml)
    assert_raises(MIME::InvalidContentType) { MIME::Type.new('apps') }
    assert_raises(MIME::InvalidContentType) { MIME::Type.new(nil) }
  end

  def test_s_simplified
    assert_equal(MIME::Type.simplified('text/plain'), 'text/plain')
    assert_equal(MIME::Type.simplified('image/jpeg'), 'image/jpeg')
    assert_equal(MIME::Type.simplified('application/x-msword'), 'application/msword')
    assert_equal(MIME::Type.simplified('text/vCard'), 'text/vcard')
    assert_equal(MIME::Type.simplified('application/pkcs7-mime'), 'application/pkcs7-mime')
    assert_equal(@zip.simplified, 'appl/zip')
    assert_equal(MIME::Type.simplified('x-xyz/abc'), 'xyz/abc')
  end
end
