$:.unshift File.dirname(__FILE__)
require 'test_helper'
require 'tmail'
require 'tmail/header'
require 'kcode'
require 'time'

class UnstructuredHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Subject SUBJECT sUbJeCt
        X-My-Header ).each do |name|
      h = TMail::HeaderField.new(name, 'This is test header.')
      assert_instance_of TMail::UnstructuredHeader, h,
                         'Header.new: name=' + name.dump
    end
  end

  def test_to_s
    # I must write more and more test.
    [
      'This is test header.',
      # "This is \r\n\ttest header"
      # "JAPANESE STRING"
      ''
    ]\
    .each do |str|
      h = TMail::HeaderField.new('Subject', str)
      assert_equal str, h.decoded
      assert_equal str, h.to_s
    end
  end
end

class DateTimeHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Date Resent-Date ).each do |name|
      h = TMail::HeaderField.new(name, 'Tue, 4 Dec 2001 10:49:32 +0900')
      assert_instance_of TMail::DateTimeHeader, h, name
    end
  end

  def test_date
    h = TMail::HeaderField.new('Date', 'Tue, 4 Dec 2001 10:49:32 +0900')
    assert_instance_of Time, h.date
    assert_equal false, h.date.gmt?
    assert_equal Time.parse('Tue, 4 Dec 2001 10:49:32 +0900'), h.date
  end

  def test_empty__illegal?
    [ [false, 'Tue,  4 Dec 2001 10:49:32 +0900'],
      [false, 'Sat, 15 Dec 2001 12:51:38 +0900'],
      [true, 'Sat, 15 Dec 2001 12:51:38'],
      [true, 'Sat, 15 Dec 2001 12:51'],
      [true, 'Sat,'] ].each do |wrong, str|

      h = TMail::HeaderField.new('Date', str)
      assert_equal wrong, h.empty?, str
      assert_equal wrong, h.illegal?, str
    end
  end

  def test_to_s
    h = TMail::HeaderField.new('Date', 'Tue, 4 Dec 2001 10:49:32 +0900')
    time = Time.parse('Tue, 4 Dec 2001 10:49:32 +0900').strftime("%a,%e %b %Y %H:%M:%S %z")
    assert_equal time, h.to_s
    assert_equal h.to_s, h.decoded
    ok = h.to_s

    h = TMail::HeaderField.new('Date', 'Tue, 4 Dec 2001 01:49:32 +0000')
    assert_equal ok, h.to_s

    h = TMail::HeaderField.new('Date', 'Tue, 4 Dec 2001 01:49:32 GMT')
    assert_equal ok, h.to_s
  end
end

class AddressHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( To Cc Bcc From Reply-To
        Resent-To Resent-Cc Resent-Bcc
        Resent-From Resent-Reply-To ).each do |name|
      h = TMail::HeaderField.new(name, 'aamine@loveruby.net')
      assert_instance_of TMail::AddressHeader, h, name
    end
  end

  def validate_case( str, isempty, to_s, comments, succ )
    h = TMail::HeaderField.new('To', str)
    assert_equal isempty, h.empty?,            str.inspect + " (empty?)\n"
    assert_instance_of Array, h.addrs,         str.inspect + " (is a)\n"
    assert_equal succ.size, h.addrs.size,      str.inspect + " (size)\n"
    h.addrs.each do |a|
      ok = succ.shift
      assert_equal ok[:phrase],   a.phrase,    str.inspect + " (phrase)\n"
      assert_equal ok[:routes],   a.routes,    str.inspect + " (routes)\n"
      assert_equal ok[:spec],     a.spec,      str.inspect + " (spec)\n"
    end
    if comments.first.respond_to? :force_encoding
      encoding = h.comments.first.encoding
      comments.each { |c| c.force_encoding encoding }
    end
    assert_equal comments, h.comments,         str.inspect + " (comments)\n"
    to_s.force_encoding(h.to_s.encoding) if to_s.respond_to? :force_encoding
    assert_equal to_s, h.to_s,                 str.inspect + " (to_s)\n" if to_s
    assert_equal to_s, h.decoded,              str.inspect + " (decoded)\n" if to_s
  end
    
  def test_ATTRS
    validate_case 'aamine@loveruby.net',
        false,
        'aamine@loveruby.net',
        [],
    [{  :phrase   => nil,
        :routes   => [],
        :spec     => 'aamine@loveruby.net' }]

    validate_case 'Minero Aoki <aamine@loveruby.net> (comment)',
        false,
        'Minero Aoki <aamine@loveruby.net> (comment)',
        ['comment'],
    [{  :phrase   => 'Minero Aoki',
        :routes   => [],
        :spec     => 'aamine@loveruby.net' }]

    validate_case 'aamine@loveruby.net, , taro@softica.org',
        false,
        'aamine@loveruby.net, taro@softica.org',
        [],
    [{  :phrase   => nil,
        :routes   => [],
        :spec     => 'aamine@loveruby.net' },
     {  :phrase   => nil,
        :routes   => [],
        :spec     => 'taro@softica.org' }]

    validate_case '',
        true,
        nil,
        [],
    []

    validate_case '(comment only)',
        true,
        nil,
        ['comment only'],
    []

    kcode('EUC') {
      validate_case 'hoge@example.jp (=?ISO-2022-JP?B?GyRCJUYlOSVIGyhC?=)',
          false,
          "hoge@example.jp (\245\306\245\271\245\310)",
          ["\245\306\245\271\245\310"],
      [{  :phrase => nil,
          :routes => [],
          :spec => 'hoge@example.jp'}]
    }
  end
end

class SingleAddressHeaderTester < Test::Unit::TestCase
  def test_s_new
    h = TMail::HeaderField.new('Sender', 'aamine@loveruby.net')
    assert_instance_of TMail::SingleAddressHeader, h
  end

  def test_addr
    h = TMail::HeaderField.new('Sender', 'aamine@loveruby.net')
    assert_not_nil h.addr
    assert_instance_of TMail::Address, h.addr
    assert_equal 'aamine@loveruby.net', h.addr.spec
    assert_equal nil, h.addr.phrase
    assert_equal [], h.addr.routes
  end

  def test_to_s
    str = 'Minero Aoki <aamine@loveruby.net>, "AOKI, Minero" <aamine@softica.org>'
    h = TMail::HeaderField.new('Sender', str)
    assert_equal 'Minero Aoki <aamine@loveruby.net>', h.to_s
  end
end

class ReturnPathHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Return-Path ).each do |name|
      h = TMail::HeaderField.new(name, '<aamine@loveruby.net>')
      assert_instance_of TMail::ReturnPathHeader, h, name
      assert_equal false, h.empty?
      assert_equal false, h.illegal?
    end
  end

  def test_ATTRS
    h = TMail::HeaderField.new('Return-Path', '<@a,@b,@c:aamine@loveruby.net>')
    assert_not_nil h.addr
    assert_instance_of TMail::Address, h.addr
    assert_equal 'aamine@loveruby.net', h.addr.spec
    assert_equal nil, h.addr.phrase
    assert_equal ['a', 'b', 'c'], h.addr.routes

    assert_not_nil h.routes
    assert_instance_of Array, h.routes
    assert_equal ['a', 'b', 'c'], h.routes
    assert_equal h.addr.routes, h.routes

    assert_not_nil h.spec
    assert_instance_of String, h.spec
    assert_equal 'aamine@loveruby.net', h.spec

    # missing '<' '>'
    h = TMail::HeaderField.new('Return-Path', 'xxxx@yyyy')
    assert_equal 'xxxx@yyyy', h.spec

    h = TMail::HeaderField.new('Return-Path', '<>')
    assert_instance_of TMail::Address, h.addr
    assert_nil h.addr.local
    assert_nil h.addr.domain
    assert_nil h.addr.spec
    assert_nil h.spec
  end

  def test_to_s
    body = 'Minero Aoki <@a,@b,@c:aamine@loveruby.net>'
    h = TMail::HeaderField.new('Return-Path', body)
    assert_equal '<@a,@b,@c:aamine@loveruby.net>', h.to_s
    assert_equal h.to_s, h.decoded

    body = 'aamine@loveruby.net'
    h = TMail::HeaderField.new('Return-Path', body)
    assert_equal '<aamine@loveruby.net>', h.to_s
    assert_equal h.to_s, h.decoded

    body = '<>'
    h = TMail::HeaderField.new('Return-Path', body)
    assert_equal '<>', h.to_s
  end
end

class MessageIdHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Message-Id MESSAGE-ID Message-ID
        Resent-Message-Id Content-Id ).each do |name|
      h = TMail::HeaderField.new(name, '<20020103xg88.k0@mail.loveruby.net>')
      assert_instance_of TMail::MessageIdHeader, h
    end
  end

  def test_id
    str = '<20020103xg88.k0@mail.loveruby.net>'
    h = TMail::HeaderField.new('Message-Id', str)
    assert_not_nil h.id
    assert_equal str, h.id

    id = '<20020103xg88.k0@mail.loveruby.net>'
    str = id + ' (comm(ent))'
    h = TMail::HeaderField.new('Message-Id', str)
    assert_not_nil h.id
    assert_equal id, h.id
  end

  def test_id=
    h = TMail::HeaderField.new('Message-Id', '')
    h.id = str = '<20020103xg88.k0@mail.loveruby.net>'
    assert_not_nil h.id
    assert_equal str, h.id
  end
end

class ReferencesHeaderTester < Test::Unit::TestCase
  def test_s_new
    str = '<20020103xg88.k0@mail.loveruby.net>'
    %w( References REFERENCES ReFeReNcEs
        In-Reply-To ).each do |name|
      h = TMail::HeaderField.new(name, str)
      assert_instance_of TMail::ReferencesHeader, h, name
    end
  end

  def test_ATTRS
    id1 = '<20020103xg88.k0@mail.loveruby.net>'
    id2 = '<20011204103415.64DB.GGB03124@nifty.ne.jp>'
    phr = 'message of "Wed, 17 Mar 1999 18:42:07 +0900"'
    str = id1 + ' ' + phr + ' ' + id2

    h = TMail::HeaderField.new('References', str)

    ok = [id1, id2]
    h.each_id do |i|
      assert_equal ok.shift, i
    end
    ok = [id1, id2]
    assert_equal ok, h.ids
    h.each_id do |i|
      assert_equal ok.shift, i
    end

    ok = [phr]
    assert_equal ok, h.phrases
    h.each_phrase do |i|
      assert_equal ok.shift, i
    end
    ok = [phr]
    h.each_phrase do |i|
      assert_equal ok.shift, i
    end


    # test 2
    # 'In-Reply-To'
    # 'aamine@dp.u-netsurf.ne.jp's message of "Fri, 8 Jan 1999 03:49:37 +0900"'
  end

  def test_to_s
    id1 = '<20020103xg88.k0@mail.loveruby.net>'
    id2 = '<20011204103415.64DB.GGB03124@nifty.ne.jp>'
    phr = 'message of "Wed, 17 Mar 1999 18:42:07 +0900"'
    str = id1 + ' ' + phr + ' ' + id2

    h = TMail::HeaderField.new('References', str)
    assert_equal id1 + ' ' + id2, h.to_s
  end
end

class ReceivedHeaderTester < Test::Unit::TestCase
  HEADER1 = <<EOS
from helium.ruby-lang.org (helium.ruby-lang.org [210.251.121.214])
	by doraemon.edit.ne.jp (8.12.1/8.12.0) via TCP with ESMTP
        id fB41nwEj007438 for <aamine@mx.edit.ne.jp>;
        Tue, 4 Dec 2001 10:49:58 +0900 (JST)
EOS
  HEADER2 = <<EOS
from helium.ruby-lang.org (localhost [127.0.0.1])
	by helium.ruby-lang.org (Postfix) with ESMTP
	id 8F8951AF3F; Tue,  4 Dec 2001 10:49:32 +0900 (JST)
EOS
  HEADER3 = <<EOS
from smtp1.dti.ne.jp (smtp1.dti.ne.jp [202.216.228.36])
	by helium.ruby-lang.org (Postfix) with ESMTP id CE3A1C3
	for <ruby-list@ruby-lang.org>; Tue,  4 Dec 2001 10:49:31 +0900 (JST)
EOS

=begin  dangerous headers
# 2-word WITH (this header is also wrong in semantic)
# I cannot support this.
Received: by mebius with Microsoft Mail
	id <01BE2B9D.9051EAA0@mebius>; Sat, 19 Dec 1998 22:18:54 -0800
=end

  def test_s_new
    %w( Received ).each do |name|
      h = TMail::HeaderField.new(name, HEADER1)
      assert_instance_of TMail::ReceivedHeader, h, name
    end
  end

  def test_ATTRS
    h = TMail::HeaderField.new('Received', HEADER1)
    assert_instance_of String, h.from
    assert_equal 'helium.ruby-lang.org', h.from

    assert_instance_of String, h.by
    assert_equal 'doraemon.edit.ne.jp', h.by

    assert_instance_of String, h.via
    assert_equal 'TCP', h.via

    assert_instance_of Array, h.with
    assert_equal %w(ESMTP), h.with

    assert_instance_of String, h.id
    assert_equal 'fB41nwEj007438', h.id

    assert_instance_of String, h._for
    assert_equal 'aamine@mx.edit.ne.jp', h._for   # must be <a> ?

    assert_instance_of Time, h.date
    time = Time.parse('Tue, 4 Dec 2001 10:49:58 +0900')
    assert_equal time, h.date

    h = TMail::HeaderField.new('Received', '; Tue, 4 Dec 2001 10:49:58 +0900')
    assert_nil h.from
    assert_nil h.by
    assert_nil h.via
    assert_equal [], h.with
    assert_nil h.id
    assert_nil h._for
    time = Time.parse('Tue, 4 Dec 2001 10:49:58 +0900')
    assert_equal time, h.date

    # without date
    h = TMail::HeaderField.new('Received', 'by NeXT.Mailer (1.144.2)')
    assert_nil h.from
    assert_equal 'NeXT.Mailer', h.by
    assert_nil h.via
    assert_equal [], h.with
    assert_nil h.id
    assert_nil h._for
    assert_nil h.date

    # FROM is not a domain
    h = TMail::HeaderField.new('Received',
        'from someuser@example.com; Tue, 24 Nov 1998 07:59:39 -0500')
    assert_equal 'example.com', h.from
    assert_nil h.by
    assert_nil h.via
    assert_equal [], h.with
    assert_nil h.id
    assert_nil h._for
    time = Time.parse('Tue, 24 Nov 1998 07:59:39 -0500')
    assert_equal time, h.date

=begin
    # FOR is not route-addr.
    # item order is wrong.
    h = TMail::HeaderField.new('Received',
        'from aamine by mail.softica.org with local for list@softica.org id 12Vm3N-00044L-01; Fri, 17 Mar 2000 10:59:53 +0900')
    assert_equal 'aamine', h.from
    assert_equal 'mail.softica.org', h.by
    assert_nil h.via
    assert_equal ['local'], h.with
    assert_equal '12Vm3N-00044L-01', h.id
    assert_equal 'list@softica.org', h._for
    assert_equal Time.local(2000,4,17, 10,59,53), h.date
=end

    # word + domain-literal in FROM

    h = TMail::HeaderField.new('Received',
        'from localhost [192.168.1.1]; Sat, 19 Dec 1998 22:19:50 PST')
    assert_equal 'localhost', h.from
    assert_nil h.by
    assert_nil h.via
    assert_equal [], h.with
    assert_nil h.id
    assert_nil h._for
    time = Time.parse('Sat, 19 Dec 1998 22:19:50 PST')
    assert_equal time, h.date

    # addr-spec in BY (must be a domain)
    h = TMail::HeaderField.new('Received',
        'by aamine@loveruby.net; Wed, 24 Feb 1999 14:34:20 +0900')
    assert_equal 'loveruby.net', h.by
  end

  def test_to_s
    h = TMail::HeaderField.new('Received', HEADER1)
    time = Time.parse('Tue, 4 Dec 2001 10:49:58 +0900').strftime("%a,%e %b %Y %H:%M:%S %z")
    assert_equal "from helium.ruby-lang.org by doraemon.edit.ne.jp via TCP with ESMTP id fB41nwEj007438 for <aamine@mx.edit.ne.jp>; #{time}", h.to_s

    [
      'from harmony.loveruby.net',
      'by mail.loveruby.net',
      'via TCP',
      'with ESMTP',
      'id LKJHSDFG',
      'for <aamine@loveruby.net>',
      "; #{time}" 
    ]\
    .each do |str|
      h = TMail::HeaderField.new('Received', str)
      assert_equal str, h.to_s, 'ReceivedHeader#to_s: data=' + str.dump
    end
  end
end

class KeywordsHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Keywords KEYWORDS KeYwOrDs ).each do |name|
      h = TMail::HeaderField.new(name, 'key, word, is, keyword')
      assert_instance_of TMail::KeywordsHeader, h
    end
  end

  def test_keys
    h = TMail::HeaderField.new('Keywords', 'key, word, is, keyword')
    assert_instance_of Array, h.keys
    assert_equal %w(key word is keyword), h.keys
  end
end

class EncryptedHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Encrypted ).each do |name|
      h = TMail::HeaderField.new(name, 'lot17 solt')
      assert_instance_of TMail::EncryptedHeader, h
    end
  end

  def test_encrypter
    h = TMail::HeaderField.new('Encrypted', 'lot17 solt')
    assert_equal 'lot17', h.encrypter
  end

  def test_encrypter=
    h = TMail::HeaderField.new('Encrypted', 'lot17 solt')
    h.encrypter = 'newscheme'
    assert_equal 'newscheme', h.encrypter
  end

  def test_keyword
    h = TMail::HeaderField.new('Encrypted', 'lot17 solt')
    assert_equal 'solt', h.keyword
    h = TMail::HeaderField.new('Encrypted', 'lot17')
    assert_equal nil, h.keyword
  end

  def test_keyword=
    h = TMail::HeaderField.new('Encrypted', 'lot17 solt')
    h.keyword = 'newscheme'
    assert_equal 'newscheme', h.keyword
  end
end

class MimeVersionHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Mime-Version MIME-VERSION MiMe-VeRsIoN ).each do |name|
      h = TMail::HeaderField.new(name, '1.0')
      assert_instance_of TMail::MimeVersionHeader, h
    end
  end

  def test_ATTRS
    h = TMail::HeaderField.new('Mime-Version', '1.0')
    assert_equal 1, h.major
    assert_equal 0, h.minor
    assert_equal '1.0', h.version

    h = TMail::HeaderField.new('Mime-Version', '99.77 (is ok)')
    assert_equal 99, h.major
    assert_equal 77, h.minor
    assert_equal '99.77', h.version
  end

  def test_major=
    h = TMail::HeaderField.new('Mime-Version', '1.1')
    h.major = 2
    assert_equal 2, h.major
    assert_equal 1, h.minor
    assert_equal 2, h.major
    h.major = 3
    assert_equal 3, h.major
  end

  def test_minor=
    h = TMail::HeaderField.new('Mime-Version', '2.3')
    assert_equal 3, h.minor
    h.minor = 5
    assert_equal 5, h.minor
    assert_equal 2, h.major
  end

  def test_to_s
    h = TMail::HeaderField.new('Mime-Version', '1.0 (first version)')
    assert_equal '1.0', h.to_s
  end

  def test_empty?
    h = TMail::HeaderField.new('Mime-Version', '')
    assert_equal true, h.empty?
  end
end

class ContentTypeHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Content-Type CONTENT-TYPE CoNtEnT-TyPe ).each do |name|
      h = TMail::HeaderField.new(name, 'text/plain; charset=iso-2022-jp')
      assert_instance_of TMail::ContentTypeHeader, h, name
    end
  end

  def test_ATTRS
    h = TMail::HeaderField.new('Content-Type', 'text/plain; charset=iso-2022-jp')
    assert_equal 'text', h.main_type
    assert_equal 'plain', h.sub_type
    assert_equal 1, h.params.size
    assert_equal 'iso-2022-jp', h.params['charset']

    h = TMail::HeaderField.new('Content-Type', 'Text/Plain; Charset=shift_jis')
    assert_equal 'text', h.main_type
    assert_equal 'plain', h.sub_type
    assert_equal 1, h.params.size
    assert_equal 'shift_jis', h.params['charset']
  end
  
  def test_multipart_with_legal_unquoted_boundary
    h = TMail::HeaderField.new('Content-Type', 'multipart/mixed; boundary=dDRMvlgZJXvWKvBx')
    assert_equal 'multipart', h.main_type
    assert_equal 'mixed', h.sub_type
    assert_equal 1, h.params.size
    assert_equal 'dDRMvlgZJXvWKvBx', h.params['boundary']
  end
  
  def test_multipart_with_legal_quoted_boundary_should_retain_quotations
    h = TMail::HeaderField.new('Content-Type', 'multipart/mixed; boundary="dDRMvlgZJXvWKvBx"')
    assert_equal 'multipart', h.main_type
    assert_equal 'mixed', h.sub_type
    assert_equal 1, h.params.size
    assert_equal 'dDRMvlgZJXvWKvBx', h.params['boundary']
  end

  def test_multipart_with_illegal_unquoted_boundary_should_add_quotations
    h = TMail::HeaderField.new('Content-Type', 'multipart/alternative; boundary=----=_=NextPart_000_0093_01C81419.EB75E850')
    assert_equal 'multipart', h.main_type
    assert_equal 'alternative', h.sub_type
    assert_equal 1, h.params.size
    assert_equal '----=_=NextPart_000_0093_01C81419.EB75E850', h.params['boundary']
  end
  
  def test_multipart_with_illegal_quoted_boundary_should_retain_quotations
    h = TMail::HeaderField.new('Content-Type', 'multipart/alternative; boundary="----=_=NextPart_000_0093_01C81419.EB75E850"')
    assert_equal 'multipart', h.main_type
    assert_equal 'alternative', h.sub_type
    assert_equal 1, h.params.size
    assert_equal '----=_=NextPart_000_0093_01C81419.EB75E850', h.params['boundary']
  end

  def test_multipart_with_extra_with_multiple_params
    h = TMail::HeaderField.new('Content-Type', 'multipart/related;boundary=1_4626B816_9F1690;Type="application/smil";Start="<mms.smil.txt>"')
    assert_equal 'multipart', h.main_type
    assert_equal 'related', h.sub_type
    assert_equal 3, h.params.size
    assert_equal '1_4626B816_9F1690', h.params['boundary']
  end

  def test_main_type=
    h = TMail::HeaderField.new('Content-Type', 'text/plain; charset=iso-2022-jp')
    assert_equal 'text', h.main_type
    h.main_type = 'multipart'
    assert_equal 'multipart', h.main_type
    assert_equal 'multipart', h.main_type
    h.main_type = 'TEXT'
    assert_equal 'text', h.main_type
  end

  def test_sub_type=
    h = TMail::HeaderField.new('Content-Type', 'text/plain; charset=iso-2022-jp')
    assert_equal 'plain', h.sub_type
    h.sub_type = 'html'
    assert_equal 'html', h.sub_type
    h.sub_type = 'PLAIN'
    assert_equal 'plain', h.sub_type
  end
end

class ContentEncodingHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Content-Transfer-Encoding CONTENT-TRANSFER-ENCODING
        COnteNT-TraNSFer-ENCodiNG ).each do |name|
      h = TMail::HeaderField.new(name, 'Base64')
      assert_instance_of TMail::ContentTransferEncodingHeader, h
    end
  end

  def test_encoding
    h = TMail::HeaderField.new('Content-Transfer-Encoding', 'Base64')
    assert_equal 'base64', h.encoding
    
    h = TMail::HeaderField.new('Content-Transfer-Encoding', '7bit')
    assert_equal '7bit', h.encoding
  end

  def test_encoding=
    h = TMail::HeaderField.new('Content-Transfer-Encoding', 'Base64')
    assert_equal 'base64', h.encoding
    h.encoding = '7bit'
    assert_equal '7bit', h.encoding
  end

  def test_to_s
    h = TMail::HeaderField.new('Content-Transfer-Encoding', 'Base64')
    assert_equal 'Base64', h.to_s
    assert_equal h.to_s, h.decoded
    assert_equal h.to_s, h.encoded
  end
  
  def test_insertion_of_headers_and_encoding_them_short
    mail = TMail::Mail.new
    mail['X-Mail-Header'] = "short bit of data"
    assert_equal("X-Mail-Header: short bit of data\r\n\r\n", mail.encoded)
  end

  def test_insertion_of_headers_and_encoding_them_more_than_78_char_total_with_whitespace
    mail = TMail::Mail.new
    mail['X-Ruby-Talk'] = "<11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA 4614-95FD-9071A4BDF4A1@grayproductions.net>"
    assert_equal("X-Ruby-Talk: <11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA\r\n\t4614-95FD-9071A4BDF4A1@grayproductions.net>\r\n\r\n", mail.encoded)
    result = TMail::Mail.parse(mail.encoded)
    assert_equal(mail['X-Ruby-Talk'].to_s, result['X-Ruby-Talk'].to_s)
  end

  def test_insertion_of_headers_and_encoding_them_more_than_78_char_total_with_whitespace
    mail = TMail::Mail.new
    mail['X-Ruby-Talk'] = "<11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA 4614-95FD-9071A4BDF4A1@grayproductions.net11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA 4614-95FD-9071A4BDF4A1@grayproductions.net>"
    assert_equal("X-Ruby-Talk: <11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA\r\n\t4614-95FD-9071A4BDF4A1@grayproductions.net11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA\r\n\t4614-95FD-9071A4BDF4A1@grayproductions.net>\r\n\r\n", mail.encoded)
    result = TMail::Mail.parse(mail.encoded)
    assert_equal(mail['X-Ruby-Talk'].to_s, result['X-Ruby-Talk'].to_s)
  end

  def test_insertion_of_headers_and_encoding_them_more_than_78_char_total_without_whitespace
    mail = TMail::Mail.new
    mail['X-Ruby-Talk'] = "<11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA-4614-95FD-9071A4BDF4A1@grayproductions.net>"
    assert_equal("X-Ruby-Talk: <11152772-AAFA-4614-95FD-9071A4BDF4A111152772-AAFA-4614-95FD-9071A4BDF4A1@grayproductions.net>\r\n\r\n", mail.encoded)
    result = TMail::Mail.parse(mail.encoded)
    assert_equal(mail['X-Ruby-Talk'].to_s, result['X-Ruby-Talk'].to_s)
  end

  def test_insertion_of_headers_and_encoding_them_less_than_998_char_total_without_whitespace
    mail = TMail::Mail.new
    text_with_whitespace = ""; 985.times{text_with_whitespace << "a"}
    mail['Reply-To'] = "#{text_with_whitespace}"
    assert_equal("Reply-To: #{text_with_whitespace}\r\n\r\n", mail.encoded)
    result = TMail::Mail.parse(mail.encoded)
    assert_equal(mail['Reply-To'].to_s, result['Reply-To'].to_s)
  end

  def test_insertion_of_headers_and_encoding_them_more_than_998_char_total_without_whitespace
    mail = TMail::Mail.new
    text_with_whitespace = ""; 1200.times{text_with_whitespace << "a"}
    before_text = ""; 985.times{before_text << "a"}
    after_text = ""; 215.times{after_text << "a"}
    mail['X-Ruby-Talk'] = "#{text_with_whitespace}"
    assert_equal("X-Ruby-Talk: #{before_text}\r\n\t#{after_text}\r\n\r\n", mail.encoded)
  end

  def test_insertion_of_headers_and_encoding_with_1_more_than_998_char_total_without_whitespace
    mail = TMail::Mail.new
    text_with_whitespace = ""; 996.times{text_with_whitespace << "a"}
    before_text = ""; 995.times{before_text << "a"}
    after_text = ""; 1.times{after_text << "a"}
    mail['X'] = "#{text_with_whitespace}"
    assert_equal("X: #{before_text}\r\n\t#{after_text}\r\n\r\n", mail.encoded)
  end

  def test_insertion_of_headers_and_encoding_with_exactly_998_char_total_without_whitespace
    mail = TMail::Mail.new
    text_with_whitespace = ""; 995.times{text_with_whitespace << "a"}
    before_text = ""; 995.times{before_text << "a"}
    mail['X'] = "#{text_with_whitespace}"
    assert_equal("X: #{before_text}\r\n\r\n", mail.encoded)
  end
end

class ContentDispositionHeaderTester < Test::Unit::TestCase
  def test_s_new
    %w( Content-Disposition CONTENT-DISPOSITION
        ConTENt-DIsPOsition ).each do |name|
      h = TMail::HeaderField.new(name, 'attachment; filename="README.txt.pif"')
      assert_instance_of TMail::ContentDispositionHeader, h
    end
  end

  def test_ATTRS
    begin
      _test_ATTRS
      _test_tspecials
      _test_rfc2231_decode
      #_test_rfc2231_encode
      _test_raw_iso2022jp
      _test_raw_eucjp
      _test_raw_sjis
      _test_code_conversion
    ensure
      TMail.KCODE = 'NONE'
    end
  end

  def _test_ATTRS
    TMail.KCODE = 'NONE'

    h = TMail::HeaderField.new('Content-Disposition',
                               'attachment; filename="README.txt.pif"')
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    assert_equal 'README.txt.pif', h.params['filename']

    h = TMail::HeaderField.new('Content-Disposition',
                               'attachment; Filename="README.txt.pif"')
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    assert_equal 'README.txt.pif', h.params['filename']
    
    h = TMail::HeaderField.new('Content-Disposition',
                               'attachment; filename=')
    assert_equal true, h.empty?
    assert_nil h.params
    assert_nil h['filename']
  end

  def _test_tspecials
    h = TMail::HeaderField.new('Content-Disposition', 'a; n=a')
    h['n'] = %q|()<>[];:@\\,"/?=|
    assert_equal 'a; n="()<>[];:@\\\\,\"/?="', h.encoded
  end

  def _test_rfc2231_decode
    TMail.KCODE = 'EUC'

    h = TMail::HeaderField.new('Content-Disposition',
            "attachment; filename*=iso-2022-jp'ja'%1b$B$Q$i$`%1b%28B")
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    expected = "\244\321\244\351\244\340"
    expected.force_encoding 'EUC-JP' if expected.respond_to? :force_encoding
    assert_equal expected, h.params['filename']
  end

  def _test_rfc2231_encode
    TMail.KCODE = 'EUC'

    h = TMail::HeaderField.new('Content-Disposition', 'a; n=a')
    h['n'] = "\245\265\245\363\245\327\245\353.txt"
    assert_equal "a; n*=iso-2022-jp'ja'%1B$B%255%25s%25W%25k%1B%28B.txt", 
                h.encoded

    h = TMail::HeaderField.new('Content-Disposition', 'a; n=a')
    h['n'] = "\245\265()<>[];:@\\,\"/?=%*'"
    assert_equal "a;\r\n\tn*=iso-2022-jp'ja'%1B$B%255%1B%28B%28%29%3C%3E%5B%5D%3B%3A%40%5C%2C%22%2F%3F%3D%25%2A%27",
                h.encoded
  end

  def _test_raw_iso2022jp
    TMail.KCODE = 'EUC'
    # raw iso2022jp string in value (token)
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename=\e$BF|K\\8l\e(B.doc>)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    # assert_equal "\e$BF|K\\8l\e(B.doc", h.params['filename']

    expected = "\306\374\313\334\270\354.doc"
    expected.force_encoding 'EUC-JP' if expected.respond_to? :force_encoding
    
    assert_equal expected, h.params['filename']
    
    # raw iso2022jp string in value (quoted string)
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename="\e$BF|K\\8l\e(B.doc">)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    # assert_equal "\e$BF|K\\8l\e(B.doc", h.params['filename']
    assert_equal expected, h.params['filename']
  end

  def _test_raw_eucjp
    TMail.KCODE = 'EUC'
    # raw EUC-JP string in value (token)
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename=\306\374\313\334\270\354.doc>)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    expected = "\306\374\313\334\270\354.doc"
    expected.force_encoding 'EUC-JP' if expected.respond_to? :force_encoding
    assert_equal expected, h.params['filename']

    # raw EUC-JP string in value (quoted-string)
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename="\306\374\313\334\270\354.doc">)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    assert_equal expected, h.params['filename']
  end

  def _test_raw_sjis
    TMail.KCODE = 'SJIS'
    # raw SJIS string in value (token)
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename=\223\372\226{\214\352.doc>)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    expected = "\223\372\226{\214\352.doc"
    expected.force_encoding 'Windows-31J' if expected.respond_to? :force_encoding
    assert_equal expected, h.params['filename']

    # raw SJIS string in value (quoted-string)
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename="\223\372\226{\214\352.doc">)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    assert_equal expected, h.params['filename']
  end

  def _test_code_conversion
    # JIS -> TMail.KCODE auto conversion
    TMail.KCODE = 'EUC'
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename=\e$BF|K\\8l\e(B.doc>)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    expected = "\306\374\313\334\270\354.doc"
    expected.force_encoding 'EUC-JP' if expected.respond_to? :force_encoding
    assert_equal expected, h.params['filename']

    TMail.KCODE = 'SJIS'
    h = TMail::HeaderField.new('Content-Disposition',
            %Q<attachment; filename=\e$BF|K\\8l\e(B.doc>)
    assert_equal 'attachment', h.disposition
    assert_equal 1, h.params.size
    expected = "\223\372\226{\214\352.doc"
    expected.force_encoding 'Windows-31J' if expected.respond_to? :force_encoding
    assert_equal expected, h.params['filename']
  end

  def test_disposition=
    h = TMail::HeaderField.new('Content-Disposition',
                               'attachment; filename="README.txt.pif"')
    assert_equal 'attachment', h.disposition
    h.disposition = 'virus'
    assert_equal 'virus', h.disposition
    h.disposition = 'AtTaChMeNt'
    assert_equal 'attachment', h.disposition
  end
  
  def test_wrong_mail_header
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email9")
    assert_raise(TMail::SyntaxError) { TMail::Mail.parse(fixture) }
  end

  def test_decode_message_with_unknown_charset
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email10")
    mail = TMail::Mail.parse(fixture)
    assert_nothing_raised { mail.body }
  end

  def test_decode_message_with_unquoted_atchar_in_header
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email11")
    mail = TMail::Mail.parse(fixture)
    assert_not_nil mail.from
  end

  def test_new_from_port_should_produce_a_header_object_of_the_correct_class
    p = TMail::FilePort.new("#{File.dirname(__FILE__)}/fixtures/mailbox")
    h = TMail::HeaderField.new_from_port(p, 'Message-Id')
    assert_equal(TMail::MessageIdHeader, h.class)
  end

  def test_should_return_the_evelope_sender_when_given_from_without_a_colon
    p = TMail::FilePort.new("#{File.dirname(__FILE__)}/fixtures/mailbox")
    h = TMail::HeaderField.new_from_port(p, 'EnvelopeSender')
    assert_equal("mike@envelope_sender.com.au", h.addrs.join)
  end
  
  def test_new_from_port_should_produce_a_header_object_that_contains_the_right_data
    p = TMail::FilePort.new("#{File.dirname(__FILE__)}/fixtures/mailbox")
    h = TMail::HeaderField.new_from_port(p, 'From')
    assert_equal("Mikel Lindsaar <mikel@from_address.com>", h.addrs.join)
  end

  def test_unwrapping_a_long_header_field_using_new_from_port
    p = TMail::FilePort.new("#{File.dirname(__FILE__)}/fixtures/mailbox")
    h = TMail::HeaderField.new_from_port(p, 'Content-Type')
    line = 'multipart/signed; protocol="application/pkcs7-signature"; boundary=Apple-Mail-42-587703407; micalg=sha1'
    assert(line =~ /multipart\/signed/)
    assert(line =~ /protocol="application\/pkcs7-signature"/)
    assert(line =~ /boundary=Apple-Mail-42-587703407/)
    assert(line =~ /micalg=sha1/)
    assert_equal(line.length, 103)
  end
  
  def test_returning_nil_if_there_is_no_match
    p = TMail::FilePort.new("#{File.dirname(__FILE__)}/fixtures/mailbox")
    h = TMail::HeaderField.new_from_port(p, 'Received-Long-Header')
    assert_equal(h, nil)
  end

end
