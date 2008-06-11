$:.unshift File.dirname(__FILE__)
require 'test_helper'
require 'tmail/address'

class TestAddress < Test::Unit::TestCase

  def test_s_new
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    assert_instance_of TMail::Address, a
    assert_nil a.phrase
    assert_equal [], a.routes
    assert_equal 'aamine@loveruby.net', a.spec
  end

  def test_local
    [ [ ['aamine'],        'aamine'        ],
      [ ['Minero Aoki'],   '"Minero Aoki"' ],
      [ ['!@#$%^&*()'],    '"!@#$%^&*()"'  ],
      [ ['a','b','c'],     'a.b.c'         ]

    ].each_with_index do |(words, ok), idx|
      a = TMail::Address.new(words, nil)
      assert_equal ok, a.local, "case #{idx+1}: #{ok.inspect}"
    end
  end

  def test_domain
    [ [ ['loveruby','net'],        'loveruby.net'    ],
      [ ['love ruby','net'],       '"love ruby".net' ],
      [ ['!@#$%^&*()'],            '"!@#$%^&*()"'    ],
      [ ['[192.168.1.1]'],         '[192.168.1.1]'   ]

    ].each_with_index do |(words, ok), idx|
      a = TMail::Address.new(%w(test), words)
      assert_equal ok, a.domain, "case #{idx+1}: #{ok.inspect}"
    end
  end

  def test_EQUAL   # ==
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    assert_equal a, a

    b = TMail::Address.new(%w(aamine), %w(loveruby net))
    b.phrase = 'Minero Aoki'
    assert_equal a, b

    b.routes.push 'a'
    assert_equal a, b
  end

  def test_hash
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    assert_equal a.hash, a.hash

    b = TMail::Address.new(%w(aamine), %w(loveruby net))
    b.phrase = 'Minero Aoki'
    assert_equal a.hash, b.hash

    b.routes.push 'a'
    assert_equal a.hash, b.hash
  end

  def test_dup
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    a.phrase = 'Minero Aoki'
    a.routes.push 'someroute'

    b = a.dup
    assert_equal a, b

    b.routes.push 'anyroute'
    assert_equal a, b

    b.phrase = 'AOKI, Minero'
    assert_equal a, b
  end

  def test_inspect
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    a.inspect
    a.phrase = 'Minero Aoki'
    a.inspect
    a.routes.push 'a'
    a.routes.push 'b'
    a.inspect
  end

  
  def validate_case__address( str, ok )
    a = TMail::Address.parse(str)
    assert_equal ok[:display_name], a.phrase, str.inspect + " (phrase)\n"
    assert_equal ok[:address],      a.spec,   str.inspect + " (spec)\n"
    assert_equal ok[:local],        a.local,  str.inspect + " (local)\n"
    assert_equal ok[:domain],       a.domain, str.inspect + " (domain)\n"
  # assert_equal ok[:format],       a.to_s,   str.inspect + " (to_s)\n"
  end

  def validate_case__group( str, groupname, addrlist )
    g = TMail::Address.parse(str)
    assert_instance_of TMail::AddressGroup, g
    assert_equal groupname, g.name
    assert_equal addrlist.size, g.size
    addrlist.each_with_index do |ok, idx|
      a = g[idx]
      assert_equal ok[:display_name], a.phrase, str.inspect + " (phrase)\n"
      assert_equal ok[:address],      a.spec,   str.inspect + " (spec)\n"
      assert_equal ok[:local],        a.local,  str.inspect + " (local)\n"
      assert_equal ok[:domain],       a.domain, str.inspect + " (domain)\n"
    # assert_equal ok[:format],       a.to_s,   str.inspect + " (to_s)\n"
    end
  end

  def test_parse__address
    #
    # basic tests
    #

    validate_case__address 'aamine@loveruby.net',
        :display_name => nil,
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'aamine@loveruby.net'

    validate_case__address 'Minero Aoki <aamine@loveruby.net>',
        :display_name => 'Minero Aoki',
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'Minero Aoki <aamine@loveruby.net>'

    validate_case__address 'Minero Aoki<aamine@loveruby.net>',
        :display_name => 'Minero Aoki',
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'Minero Aoki <aamine@loveruby.net>'

    validate_case__address '"Minero Aoki" <aamine@loveruby.net>',
        :display_name => 'Minero Aoki',
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'Minero Aoki <aamine@loveruby.net>'

    # integer in domain
    validate_case__address 'Minero Aoki<aamine@0246.loveruby.net>',
        :display_name => 'Minero Aoki',
        :address      => 'aamine@0246.loveruby.net',
        :local        => 'aamine',
        :domain       => '0246.loveruby.net',
        :format       => 'Minero Aoki <aamine@0246.loveruby.net>'

  end

  def test_parse__dot
    validate_case__address 'hoge..test@docomo.ne.jp',
        :display_name => nil,
        :address      => 'hoge..test@docomo.ne.jp',
        :local        => 'hoge..test',
        :domain       => 'docomo.ne.jp',
        :format       => 'hoge..test@docomo.ne.jp'

    validate_case__address 'foo.bar.@docomo.ne.jp',
        :display_name => nil,
        :address      => 'foo.bar.@docomo.ne.jp',
        :local        => 'foo.bar.',
        :domain       => 'docomo.ne.jp',
        :format       => 'foo.bar.@docomo.ne.jp'
  end

  def test_parse__mime
    # "\306\374\313\334\270\354"
    # "\223\372\226{\214\352"
    # "\e$BF|K\\8l\e(B"
    # GyRCRnxLXDhsGyhC

    TMail.KCODE = 'NONE'
    validate_case__address\
    '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>',
        :display_name => "\e$BF|K\\8l\e(B",
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>'

    validate_case__address\
    '=?iso-2022-jp?Q?=1b=24=42=46=7c=4b=5c=38=6c=1b=28=42?= <aamine@loveruby.net>',
        :display_name => "\e$BF|K\\8l\e(B",
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>'

    TMail.KCODE = 'EUC'
    expected = "\306\374\313\334\270\354"
    expected.force_encoding('EUC-JP') if expected.respond_to? :force_encoding
    validate_case__address\
    '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>',
        :display_name => expected,
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>'

    validate_case__address\
    '=?iso-2022-jp?Q?=1b=24=42=46=7c=4b=5c=38=6c=1b=28=42?= <aamine@loveruby.net>',
        :display_name => expected,
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>'

    TMail.KCODE = 'SJIS'
    expected = "\223\372\226{\214\352"
    expected.force_encoding('Windows-31J') if expected.respond_to? :force_encoding
    validate_case__address\
    '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>',
        :display_name => expected,
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>'

    validate_case__address\
    '=?iso-2022-jp?Q?=1b=24=42=46=7c=4b=5c=38=6c=1b=28=42?= <aamine@loveruby.net>',
        :display_name => expected,
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => '=?iso-2022-jp?B?GyRCRnxLXDhsGyhC?= <aamine@loveruby.net>'
  end

  def test_parse__rawjp
    begin
      TMail.KCODE = 'EUC'
      _test_parse__euc
      _test_parse__jis
    ensure
      TMail.KCODE = 'NONE'
    end
  end

  def _test_parse__euc
    # raw EUC-JP
    validate_case__address\
    "\244\242\244\252\244\255 \244\337\244\315\244\355\244\246 <aamine@loveruby.net>",
        :display_name => "\244\242\244\252\244\255 \244\337\244\315\244\355\244\246",
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => "\244\242\244\252\244\255 \244\337\244\315\244\355\244\246 <aamine@loveruby.net>"
  end

  def _test_parse__jis
    # raw iso-2022-jp string in comment
    validate_case__address\
    "Minero Aoki (\e$B@DLZJvO:\e(B) <aamine@loveruby.net>",
        :display_name => "Minero Aoki (\e$B@DLZJvO:\e(B)",
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'Minero Aoki <aamine@loveruby.net>'

    validate_case__address\
    "Minero Aoki <aamine@loveruby.net> (\e$B@DLZJvO:\e(B )",
        :display_name => 'Minero Aoki',
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'Minero Aoki <aamine@loveruby.net>'
    
    # raw iso-2022-jp string in quoted-word (it includes backslash)
    validate_case__address\
    %Q["\e$BF|K\\8l\e(B" <aamine@loveruby.net>],
        :display_name => "\e$BF|K\\8l\e(B",
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'Minero Aoki <aamine@loveruby.net>'
  end

  def OFF_test_parse__group
    validate_case__group 'Softica: Minero Aoki <aamine@loveruby.net>;',
        'Softica',
    {   :display_name => 'Minero Aoki',
        :address      => 'aamine@loveruby.net',
        :local        => 'aamine',
        :domain       => 'loveruby.net',
        :format       => 'Minero Aoki <aamine@loveruby.net>' }
  end


  #
  # The following test cases are quoted from RubyMail 0.2
  # (written by Matt Armstrong), with some modifications.
  # The copyright notice of the original file is:
  # 
  #   Copyright (c) 2001 Matt Armstrong.  All rights reserved.
  #
  #   Permission is granted for use, copying, modification,
  #   distribution, and distribution of modified versions of this work
  #   as long as the above copyright notice is included.
  #

  def test_parse__rfc2822

    validate_case__address\
    '"Joe Q. Public" <john.q.public@example.com>',
        :name         => 'Joe Q. Public',
        :display_name => 'Joe Q. Public',
        :address      => 'john.q.public@example.com',
        :comments     => nil,
        :domain       => 'example.com',
        :local        => 'john.q.public',
        :format       => '"Joe Q. Public" <john.q.public@example.com>'

    validate_case__address\
    'Who? <one@y.test>',
        :name         => 'Who?',
        :display_name => 'Who?',
        :address      => 'one@y.test',
        :comments     => nil,
        :domain       => 'y.test',
        :local        => 'one',
        :format       => 'Who? <one@y.test>'

    validate_case__address\
    '"Giant; \"Big\" Box" <sysservices@example.net>',
        :name         => 'Giant; "Big" Box',
        :display_name => 'Giant; "Big" Box',
        :address      => 'sysservices@example.net',
        :comments     => nil,
        :domain       => 'example.net',
        :local        => 'sysservices',
        :format       => '"Giant; \"Big\" Box" <sysservices@example.net>'

    validate_case__address\
    '"Mary Smith: Personal Account" <smith@home.example>   ',
        :name         => 'Mary Smith: Personal Account',
        :display_name => 'Mary Smith: Personal Account',
        :address      => 'smith@home.example',
        :comments     => nil,
        :domain       => 'home.example',
        :local        => 'smith',
        :format       => '"Mary Smith: Personal Account" <smith@home.example>'

    validate_case__address\
    'Pete(A wonderful \) chap) <pete(his account)@silly.test(his host)>',
        :name         => 'Pete',
        :display_name => 'Pete',
        :address      => 'pete@silly.test',
        :comments     => ['A wonderful ) chap', 'his account', 'his host'],
        :domain       => 'silly.test',
        :local        => 'pete',
        #:format       => 'Pete <pete@silly.test> (A wonderful \) chap) (his account) (his host)'
        :format       => 'Pete <pete@silly.test>'

    validate_case__address\
    "Chris Jones <c@(Chris's host.)public.example>",
        :name         => 'Chris Jones',
        :display_name => 'Chris Jones',
        :address      => 'c@public.example',
        :comments     => ['Chris\'s host.'],
        :domain       => 'public.example',
        :local        => 'c',
        #:format       => 'Chris Jones <c@public.example> (Chris\'s host.)'
        :format       => 'Chris Jones <c@public.example>'

    validate_case__address\
    'Joe Q. Public <john.q.public@example.com>',
        :name         => 'Joe Q.Public',
        :display_name => 'Joe Q.Public',
        :address      => 'john.q.public@example.com',
        :comments     => nil,
        :domain       => 'example.com',
        :local        => 'john.q.public',
        :format       => '"Joe Q.Public" <john.q.public@example.com>'
	
    validate_case__address\
    'Mary Smith <@machine.tld:mary@example.net>',
        :name         => 'Mary Smith',
        :display_name => 'Mary Smith',
        :address      => 'mary@example.net',
        :comments     => nil,
        :domain       => 'example.net',
        :local        => 'mary',
        #:format       => 'Mary Smith <mary@example.net>'
        :format       => 'Mary Smith <@machine.tld:mary@example.net>'

    validate_case__address\
    '  jdoe@test   . example',
        :name         => nil,
        :display_name => nil,
        :address      => 'jdoe@test.example',
        :comments     => nil,
        :domain       => 'test.example',
        :local        => 'jdoe',
        :format       => 'jdoe@test.example' 

    validate_case__address\
    'John Doe <jdoe@machine(comment).  example>',
        :name         => 'John Doe',
        :display_name => 'John Doe',
        :address      => 'jdoe@machine.example',
        :comments     => ['comment'],
        :domain       => 'machine.example',
        :local        => 'jdoe',
        #:format       => 'John Doe <jdoe@machine.example> (comment)'
        :format       => 'John Doe <jdoe@machine.example>'

    validate_case__address\
    "Mary Smith\n\r                  \n          <mary@example.net>",
        :name         => 'Mary Smith',
        :display_name => 'Mary Smith',
        :address      => 'mary@example.net',
        :comments     => nil,
        :domain       => 'example.net',
        :local        => 'mary',
        :format       => 'Mary Smith <mary@example.net>'
  end


  def test_parse__rfc822

    validate_case__address\
    '":sysmail"@ Some-Group. Some-Org',
        :name         => nil,
        :display_name => nil,
        #:address      => ':sysmail@Some-Group.Some-Org',
        :address      => '":sysmail"@Some-Group.Some-Org',
        :comments     => nil,
        :domain       => 'Some-Group.Some-Org',
        #:local        => ':sysmail',
        :local        => '":sysmail"',
        :format       => '":sysmail"@Some-Group.Some-Org'

    validate_case__address\
    'Muhammed.(I am the greatest) Ali @(the)Vegas.WBA',
        :name         => 'the',
        :display_name => nil,
        :address      => 'Muhammed.Ali@Vegas.WBA',
        :comments     => ['I am the greatest', 'the'],
        :domain       => 'Vegas.WBA',
        :local        => 'Muhammed.Ali',
        #:format       => 'Muhammed.Ali@Vegas.WBA (I am the greatest) (the)'
        :format       => 'Muhammed.Ali@Vegas.WBA'


    validate_case__group\
    'A Group:Chris Jones <c@a.test>,joe@where.test,John <jdoe@one.test>;',
    'A Group',
    [ { :name         => 'Chris Jones',
        :display_name => 'Chris Jones',
        :address      => 'c@a.test',
        :comments     => nil,
        :domain       => 'a.test',
        :local        => 'c',
        :format       => 'Chris Jones <c@a.test>' },
      { :name         => nil,
        :display_name => nil,
        :address      => 'joe@where.test',
        :comments     => nil,
        :domain       => 'where.test',
        :local        => 'joe',
        :format       => 'joe@where.test' },
      { :name         => 'John',
        :display_name => 'John',
        :address      => 'jdoe@one.test',
        :comments     => nil,
        :domain       => 'one.test',
        :local        => 'jdoe',
        :format       => 'John <jdoe@one.test>' }
    ]

    validate_case__group\
    'Undisclosed recipients:;',
    'Undisclosed recipients',
    [ ]

    validate_case__group\
    'undisclosed recipients: ;',
    'undisclosed recipients',
    []

    validate_case__group\
    "A Group(Some people)\r\n     :Chris Jones <c@(Chris's host.)public.example>,\r\n         joe@example.org",
    'A Group',
    [
      { :name         => 'Chris Jones',
        :display_name => 'Chris Jones',
        :address      => 'c@public.example',
        :comments     => ['Chris\'s host.'],
        :domain       => 'public.example',
        :local        => 'c',
        :format       => 'Chris Jones <c@public.example> (Chris\'s host.)' },
      { :name         => nil,
        :display_name => nil,
        :address      => 'joe@example.org',
        :comments     => nil,
        :domain       => 'example.org',
        :local        => 'joe',
        :format       => 'joe@example.org' }
    ]

    validate_case__group\
    '(Empty list)(start)Undisclosed recipients  :(nobody(that I know))  ;',
    'Undisclosed recipients',
    []
  end


  def test_parse__mailtools
    #
    # The following are from the Perl MailTools module version 1.40
    #
    validate_case__address\
    '"Joe & J. Harvey" <ddd @Org>',
        :name         => 'Joe & J. Harvey',
        :display_name => 'Joe & J. Harvey',
        :address      => 'ddd@Org',
        :comments     => nil,
        :domain       => 'Org',
        :local        => 'ddd',
        :format       => '"Joe & J. Harvey" <ddd@Org>'

    validate_case__address\
    '"spickett@tiac.net" <Sean.Pickett@zork.tiac.net>',
        :name         => 'spickett@tiac.net',
        :display_name => 'spickett@tiac.net',
        :address      => 'Sean.Pickett@zork.tiac.net',
        :comments     => nil,
        :domain       => 'zork.tiac.net',
        :local        => 'Sean.Pickett',
        :format       => '"spickett@tiac.net" <Sean.Pickett@zork.tiac.net>'

    validate_case__address\
    'rls@intgp8.ih.att.com (-Schieve,R.L.)',
        :name         => '-Schieve,R.L.',
        :display_name => nil,
        :address      => 'rls@intgp8.ih.att.com',
        :comments     => ['-Schieve,R.L.'],
        :domain       => 'intgp8.ih.att.com',
        :local        => 'rls',
        #:format       => 'rls@intgp8.ih.att.com (-Schieve,R.L.)'
        :format       => 'rls@intgp8.ih.att.com'

    validate_case__address\
    'jrh%cup.portal.com@portal.unix.portal.com',
        :name         => nil,
        :display_name => nil,
        :address      => 'jrh%cup.portal.com@portal.unix.portal.com',
        :comments     => nil,
        :domain       => 'portal.unix.portal.com',
        :local        => 'jrh%cup.portal.com',
        :format       => 'jrh%cup.portal.com@portal.unix.portal.com'

    validate_case__address\
    'astrachan@austlcm.sps.mot.com (\'paul astrachan/xvt3\')',
        :name         => '\'paul astrachan/xvt3\'',
        :display_name => nil,
        :address      => 'astrachan@austlcm.sps.mot.com',
        :comments     => ["'paul astrachan/xvt3'"],
        :domain       => 'austlcm.sps.mot.com',
        :local        => 'astrachan',
        #:format => "astrachan@austlcm.sps.mot.com ('paul astrachan/xvt3')"
        :format       => 'astrachan@austlcm.sps.mot.com'

    validate_case__address\
    'TWINE57%SDELVB.decnet@SNYBUF.CS.SNYBUF.EDU (JAMES R. TWINE - THE NERD)',
        :name         => 'JAMES R. TWINE - THE NERD',
        :display_name => nil,
        :address      => 'TWINE57%SDELVB.decnet@SNYBUF.CS.SNYBUF.EDU',
        :comments     => ['JAMES R. TWINE - THE NERD'],
        :domain       => 'SNYBUF.CS.SNYBUF.EDU',
        :local        => 'TWINE57%SDELVB.decnet',
        :format       => 'TWINE57%SDELVB.decnet@SNYBUF.CS.SNYBUF.EDU'
	#'TWINE57%SDELVB.decnet@SNYBUF.CS.SNYBUF.EDU (JAMES R. TWINE - THE NERD)'

    validate_case__address\
    'David Apfelbaum <da0g+@andrew.cmu.edu>',
        :name         => 'David Apfelbaum',
        :display_name => 'David Apfelbaum',
        :address      => 'da0g+@andrew.cmu.edu',
        :comments     => nil,
        :domain       => 'andrew.cmu.edu',
        :local        => 'da0g+',
        :format       => 'David Apfelbaum <da0g+@andrew.cmu.edu>'

    validate_case__address\
    '"JAMES R. TWINE - THE NERD" <TWINE57%SDELVB%SNYDELVA.bitnet@CUNYVM.CUNY.EDU>',
        :name         => 'JAMES R. TWINE - THE NERD',
        :display_name => 'JAMES R. TWINE - THE NERD',
        :address      => 'TWINE57%SDELVB%SNYDELVA.bitnet@CUNYVM.CUNY.EDU',
        :comments     => nil,
        :domain       => 'CUNYVM.CUNY.EDU',
        :local        => 'TWINE57%SDELVB%SNYDELVA.bitnet',
        :format       =>
  '"JAMES R. TWINE - THE NERD" <TWINE57%SDELVB%SNYDELVA.bitnet@CUNYVM.CUNY.EDU>'

    validate_case__address\
    '/G=Owen/S=Smith/O=SJ-Research/ADMD=INTERSPAN/C=GB/@mhs-relay.ac.uk',
        :name         => nil,
        :display_name => nil,
        :address      => '/G=Owen/S=Smith/O=SJ-Research/ADMD=INTERSPAN/C=GB/@mhs-relay.ac.uk',
        :comments     => nil,
        :domain       => 'mhs-relay.ac.uk',
        :local        => '/G=Owen/S=Smith/O=SJ-Research/ADMD=INTERSPAN/C=GB/',
        :format       => '/G=Owen/S=Smith/O=SJ-Research/ADMD=INTERSPAN/C=GB/@mhs-relay.ac.uk'

    validate_case__address\
    '"Stephen Burke, Liverpool" <BURKE@vxdsya.desy.de>',
        :name         => 'Stephen Burke, Liverpool',
        :display_name => 'Stephen Burke, Liverpool',
        :address      => 'BURKE@vxdsya.desy.de',
        :comments     => nil,
        :domain       => 'vxdsya.desy.de',
        :local        => 'BURKE',
        :format       => '"Stephen Burke, Liverpool" <BURKE@vxdsya.desy.de>'

    validate_case__address\
    'The Newcastle Info-Server <info-admin@newcastle.ac.uk>',
        :name         => 'The Newcastle Info-Server',
        :display_name => 'The Newcastle Info-Server',
        :address      => 'info-admin@newcastle.ac.uk',
        :comments     => nil,
        :domain       => 'newcastle.ac.uk',
        :local        => 'info-admin',
        :format       => 'The Newcastle Info-Server <info-admin@newcastle.ac.uk>'

    validate_case__address\
    'Suba.Peddada@eng.sun.com (Suba Peddada [CONTRACTOR])',
        :name         => 'Suba Peddada [CONTRACTOR]',
        :display_name => nil,
        :address      => 'Suba.Peddada@eng.sun.com',
        :comments     => ['Suba Peddada [CONTRACTOR]'],
        :domain       => 'eng.sun.com',
        :local        => 'Suba.Peddada',
        #:format       => 'Suba.Peddada@eng.sun.com (Suba Peddada [CONTRACTOR])'
        :format       => 'Suba.Peddada@eng.sun.com'

    validate_case__address\
    'Paul Manser (0032 memo) <a906187@tiuk.ti.com>',
        :name         => 'Paul Manser',
        :display_name => 'Paul Manser',
        :address      => 'a906187@tiuk.ti.com',
        :comments     => ['0032 memo'],
        :domain       => 'tiuk.ti.com',
        :local        => 'a906187',
        #:format       => 'Paul Manser <a906187@tiuk.ti.com> (0032 memo)'
        :format       => 'Paul Manser <a906187@tiuk.ti.com>'

    validate_case__address\
    '"gregg (g.) woodcock" <woodcock@bnr.ca>',
        :name         => 'gregg (g.) woodcock',
        :display_name => 'gregg (g.) woodcock',
        :address      => 'woodcock@bnr.ca',
        :comments     => nil,
        :domain       => 'bnr.ca',
        :local        => 'woodcock',
        :format       => '"gregg (g.) woodcock" <woodcock@bnr.ca>'

    validate_case__address\
    'Graham.Barr@tiuk.ti.com',
        :name         => nil,
        :display_name => nil,
        :address      => 'Graham.Barr@tiuk.ti.com',
        :comments     => nil,
        :domain       => 'tiuk.ti.com',
        :local        => 'Graham.Barr',
        :format       => 'Graham.Barr@tiuk.ti.com'

    validate_case__address\
    'a909937 (Graham Barr          (0004 bodg))',
        :name         => 'Graham Barr (0004 bodg)',
        :display_name => nil,
        :address      => 'a909937',
        :comments     => ['Graham Barr (0004 bodg)'],
        :domain       => nil,
        :local        => 'a909937',
        #:format       => 'a909937 (Graham Barr \(0004 bodg\))'
        :format       => 'a909937'

    validate_case__address\
    "david d `zoo' zuhn <zoo@aggregate.com>",
        :name         => "david d `zoo' zuhn",
        :display_name => "david d `zoo' zuhn",
        :address      => 'zoo@aggregate.com',
        :comments     => nil,
        :domain       => 'aggregate.com',
        :local        => 'zoo',
        :format       => "david d `zoo' zuhn <zoo@aggregate.com>"

    validate_case__address\
    '(foo@bar.com (foobar), ned@foo.com (nedfoo) ) <kevin@goess.org>',
        :name         => 'foo@bar.com (foobar), ned@foo.com (nedfoo) ',
        :display_name => "(foo@bar.com (foobar), ned@foo.com (nedfoo) )",
        :address      => 'kevin@goess.org',
        :comments     => ['foo@bar.com (foobar), ned@foo.com (nedfoo) '],
        :domain       => 'goess.org',
        :local        => 'kevin',
        :format       => 'kevin@goess.org'
	#'kevin@goess.org (foo@bar.com \(foobar\), ned@foo.com \(nedfoo\) )'
  end


  def test_parse__pythonbuglist
    #
    # From Python address parsing bug list.
    # This is valid according to RFC2822.
    #

    validate_case__address\
    'Amazon.com <delivers-news2@amazon.com>',
        :name         => 'Amazon.com',
        :display_name => 'Amazon.com',
        :address      => 'delivers-news2@amazon.com',
        :comments     => nil,
        :domain       => 'amazon.com',
        :local        => 'delivers-news2',
        :format       => '"Amazon.com" <delivers-news2@amazon.com>'

    validate_case__address\
    "\r\n  Amazon \r . \n com \t <    delivers-news2@amazon.com  >  \n  ",
        :name         => 'Amazon.com',
        :display_name => 'Amazon.com',
        :address      => 'delivers-news2@amazon.com',
        :comments     => nil,
        :domain       => 'amazon.com',
        :local        => 'delivers-news2',
        :format       => '"Amazon.com" <delivers-news2@amazon.com>'

    # From postfix-users@postfix.org
    # Date: Tue, 13 Nov 2001 10:58:23 -0800
    # Subject: Apparent bug in strict_rfc821_envelopes (Snapshot-20010714)
    validate_case__address\
    '"mailto:rfc"@monkeys.test',
        :name         => nil,
        :display_name => nil,
        #:address      => 'mailto:rfc@monkeys.test',
        :address      => '"mailto:rfc"@monkeys.test',
        :comments     => nil,
        :domain       => 'monkeys.test',
        #:local        => 'mailto:rfc',
        :local        => '"mailto:rfc"',
        :format       => '"mailto:rfc"@monkeys.test'

    # An unquoted mailto:rfc will end up having the mailto: portion
    # discarded as a group name.
    validate_case__group\
    'mailto:rfc@monkeys.test',
    'mailto',
    [
      { :name         => nil,
        :display_name => nil,
        :address      => 'rfc@monkeys.test',
        :comments     => nil,
        :domain       => 'monkeys.test',
        :local        => 'rfc',
        :format       => 'rfc@monkeys.test' }
    ]

    # From gnu.emacs.help
    # Date: 24 Nov 2001 15:37:23 -0500
    validate_case__address\
    '"Stefan Monnier <foo@acm.com>" <monnier+gnu.emacs.help/news/@flint.cs.yale.edu>',
        :name         => 'Stefan Monnier <foo@acm.com>',
        :display_name => 'Stefan Monnier <foo@acm.com>',
        :address      => 'monnier+gnu.emacs.help/news/@flint.cs.yale.edu',
        :comments     => nil,
        :domain       => 'flint.cs.yale.edu',
        :local        => 'monnier+gnu.emacs.help/news/',
        :format       => '"Stefan Monnier <foo@acm.com>" <monnier+gnu.emacs.help/news/@flint.cs.yale.edu>'

    validate_case__address\
    '"foo:" . bar@somewhere.test',
        :name         => nil,
        :display_name => nil,
        #:address      => 'foo:.bar@somewhere.test',
        :address      => '"foo:".bar@somewhere.test',
        :comments     => nil,
        :domain       => 'somewhere.test',
        #:local        => 'foo:.bar',
        :local        => '"foo:".bar',
        #:format       => '"foo:.bar"@somewhere.test'
        :format       => '"foo:".bar@somewhere.test'

    validate_case__address\
    'Some Dude <"foo:" . bar@somewhere.test>',
        :name         => 'Some Dude',
        :display_name => 'Some Dude',
        #:address      => 'foo:.bar@somewhere.test',
        :address      => '"foo:".bar@somewhere.test',
        :comments     => nil,
        :domain       => 'somewhere.test',
        #:local        => 'foo:.bar',
        :local        => '"foo:".bar',
        #:format       => 'Some Dude <"foo:.bar"@somewhere.test>'
        :format       => 'Some Dude <"foo:".bar@somewhere.test>'

    validate_case__address\
    '"q\uo\ted"@example.com',
        :name         => nil,
        :display_name => nil,
        :address      => 'quoted@example.com',
        :comments     => nil,
        :domain       => 'example.com',
        :local        => 'quoted',
        :format       => 'quoted@example.com'

    validate_case__address\
    'Luke Skywalker <"use"."the.force"@space.test>',
        :name         => 'Luke Skywalker',
        :display_name => 'Luke Skywalker',
        #:address      => 'use.the.force@space.test',
        :address      => 'use."the.force"@space.test',
        :comments     => nil,
        :domain       => 'space.test',
        #:local        => 'use.the.force',
        :local        => 'use."the.force"',
        #:format       => 'Luke Skywalker <use.the.force@space.test>'
        :format       => 'Luke Skywalker <use."the.force"@space.test>'

    validate_case__address\
    'Erik =?ISO-8859-1?Q?B=E5gfors?= <erik@example.net>',
        :name         => 'Erik =?ISO-8859-1?Q?B=E5gfors?=',
        :display_name => 'Erik =?ISO-8859-1?Q?B=E5gfors?=',
        :address      => 'erik@example.net',
        :comments     => nil,
        :domain       => 'example.net',
        :local        => 'erik',
        :format       => 'Erik =?ISO-8859-1?Q?B=E5gfors?= <erik@example.net>'
  end

  def test_parse__outofspec

=begin
    validate_case__address\
    'bodg fred@tiuk.ti.com',
        :name         => nil,
        :display_name => nil,
        :address      => 'bodg fred@tiuk.ti.com',
        :comments     => nil,
        :domain       => 'tiuk.ti.com',
        :local        => 'bodg fred',
        :format       => '"bodg fred"@tiuk.ti.com'

    validate_case__address\
    '<Investor Alert@example.com>',
        :name         => nil,
        :display_name => nil,
        :address      => 'Investor Alert@example.com',
        :comments     => nil,
        :domain       => 'example.com',
        :local        => 'Investor Alert',
        :format       => '"Investor Alert"@example.com'
=end
    
    validate_case__address\
    '"" <bob@example.com>',
        :name         => nil,
        :display_name => nil,
        :address      => 'bob@example.com',
        :comments     => nil,
        :domain       => 'example.com',
        :local        => 'bob',
        :format       => 'bob@example.com'

    validate_case__address '"" <""@example.com>',
        :name         => nil,
        :display_name => nil,
        :address      => '""@example.com',
        :comments     => nil,
        :domain       => 'example.com',
        :local        => '""',
        :format       => '""@example.com'

    assert_raise(TMail::SyntaxError) {
      TMail::Address.parse '@example.com'
    }

    validate_case__address\
    'bob',
        :name         => nil,
        :display_name => nil,
        :address      => 'bob',
        :comments     => nil,
        :domain       => nil,
        :local        => 'bob',
        :format       => 'bob'

    assert_raises(TMail::SyntaxError) {
      TMail::Address.parse 'Undisclosed <>'
    }
    assert_raises(TMail::SyntaxError) {
      TMail::Address.parse '"Mensagem Automatica do Terra" <>'
    }

    # These test cases are meanful in Japanese charset context.
    # validate_case(["\177", []])
    # validate_case(["\177\177\177", []])

  end

  def test_parse__domainliteral

    validate_case__address\
    'test@[domain]',
        :name         => nil,
        :display_name => nil,
        :address      => 'test@[domain]',
        :comments     => nil,
        :domain       => '[domain]',
        :local        => 'test',
        :format       => '<test@[domain]>'

    validate_case__address\
    '<@[obsdomain]:test@[domain]>',
        :name         => nil,
        :display_name => nil,
        :address      => 'test@[domain]',
        :comments     => nil,
        :domain       => '[domain]',
        :local        => 'test',
        :format       => '<test@[domain]>'

    validate_case__address\
    '<@[ob\]sd\\\\omain]:test@[dom\]ai\\\\n]>',
        :name         => nil,
        :display_name => nil,
        :address      => 'test@[dom]ai\\n]',
        :comments     => nil,
        :domain       => '[dom]ai\\n]',
        :local        => 'test',
        :format       => '<test@[dom\]ai\\\\n]>'

    # ALL 'route's have '@' prefix so this example is wrong.
    #"Bob \r<@machine.tld  \r,\n [obsdomain]\t:\ntest @ [domain]>",
    validate_case__address\
    "Bob \r<@machine.tld  \r,\n @[obsdomain]\t:\ntest @ [domain]>",
        :name         => 'Bob',
        :display_name => 'Bob',
        :address      => 'test@[domain]',
        :comments     => nil,
        :domain       => '[domain]',
        :local        => 'test',
        :format       => 'Bob <test@[domain]>'
  end


  def test_exhaustive()

    # We don't test every alphanumeric in atext -- assume that if a, m
    # and z work, they all will.
    atext = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a +
      '!#$%&\'*+-/=?^_`{|}~'.split(//) #/
    boring = ('b'..'l').to_a + ('n'..'o').to_a +
      ('p'..'y').to_a + ('B'..'L').to_a + ('N'..'O').to_a +
      ('P'..'Y').to_a + ('1'..'4').to_a + ('6'..'8').to_a

    (atext - boring).each do |ch|
      validate_case__address\
      "#{ch} <#{ch}@test>",
          :name         => ch,
          :display_name => ch,
          :address      => "#{ch}@test",
          :comments     => nil,
          :domain       => 'test',
          :local        => ch,
          :format       => ch + ' <' + ch + '@test>'
    end
    
    validate_case__address\
    atext.join('') + ' <' + atext.join('') + '@test>',
        :name         => atext.join(''),
        :display_name => atext.join(''),
        :address      => atext.join('') + '@test',
        :comments     => nil,
        :domain       => 'test',
        :local        => atext.join(''),
        :format       => atext.join('') + ' <' + atext.join('') + '@test>'

    ascii = (0..127).collect {|i| i.chr }
    whitespace = ["\r", "\n", ' ', "\t"]
    # I remove ESC from this list because TMail is ESC sensitive.
    # @ is explicitly tested below
    qtext = ascii - (whitespace + ['"', '\\']         + ["\e"] + ["@"])
    ctext = ascii - (whitespace + ['(', ')', '\\']    + ["\e"] + ["@"])
    dtext = ascii - (whitespace + ['[', ']', '\\']    + ["\e"] + ["@"])

    (qtext - atext).each do |ch|
      validate_case__address\
      %Q("#{ch}" <"#{ch}"@test>),
          :name         => ch,
          :display_name => ch,
          :address      => %Q("#{ch}"@test),
          :comments     => nil,
          :domain       => 'test',
          :local        => %Q("#{ch}"),
          :format       => %Q("#{ch}" <"#{ch}"@test>)
    end
    
    ['"', "\\"].each do |ch|
      validate_case__address\
      %Q("\\#{ch}" <"\\#{ch}"@test>),
          :name         => ch,
          :display_name => ch,
          :address      => %Q("\\#{ch}"@test),
          :comments     => nil,
          :domain       => 'test',
          :local        => %Q("\\#{ch}"),
          :format       => %Q("\\#{ch}" <"\\#{ch}"@test>)

    end

    (ctext - boring).each do |ch|
      validate_case__address\
      "bob@test (#{ch})",
          :name         => ch,
          :display_name => nil,
          :address      => 'bob@test',
          :comments     => ["#{ch}"],
          :domain       => 'test',
          :local        => 'bob',
          :format       => "bob@test (#{ch})"

      validate_case__address\
      "bob@test (\\#{ch})",
          :name         => ch,
          :display_name => nil,
          :address      => 'bob@test',
          :comments     => ["#{ch}"],
          :domain       => 'test',
          :local        => 'bob',
          :format       => "bob@test (#{ch})"
    end
    [')', '(', '\\'].each do |ch|
      validate_case__address\
      "bob@test (\\#{ch})",
          :name         => ch,
          :display_name => nil,
          :address      => 'bob@test',
          :comments     => ["#{ch}"],
          :domain       => 'test',
          :local        => 'bob',
          :format       => "bob@test (\\#{ch})"
    end


    (dtext - boring).each do |ch|
      validate_case__address\
      "test@[\\#{ch}] (Sam)",
          :name         => "Sam",
          :display_name => nil,
          :address      => 'test@[' + ch + ']',
          :comments     => ["Sam"],
          :domain       => '[' + ch + ']',
          :local        => 'test',
          :format       => "<test@[#{ch}]> (Sam)"

      validate_case__address\
      "Sally <test@[\\#{ch}]>",
          :name         => 'Sally',
          :display_name => 'Sally',
          :address      => "test@[#{ch}]",
          :comments     => nil,
          :domain       => "[#{ch}]",
          :local        => 'test',
          :format       => "Sally <test@[#{ch}]>"
    end

    validate_case__address\
    "test@[" + (dtext - boring).join('') + "]",
        :name         => nil,
        :display_name => nil,
        :address      => 'test@[' + (dtext - boring).join('') + "]",
        :comments     => nil,
        :domain       => '[' + (dtext - boring).join('') + ']',
        :local        => 'test',
        :format       => '<test@[' + (dtext - boring).join('') + ']>'

    validate_case__address\
    'Bob <test@[' + (dtext - boring).join('') + ']>',
        :name         => "Bob",
        :display_name => "Bob",
        :address      => 'test@[' + (dtext - boring).join('') + "]",
        :comments     => nil,
        :domain       => '[' + (dtext - boring).join('') + ']',
        :local        => 'test',
        :format       => 'Bob <test@[' + (dtext - boring).join('') + ']>'

  end

  def test_quoted_at_char_in_local()
      
    validate_case__address\
    %Q("@" <"@"@test>),
        :name         => "@",
        :display_name => "@",
        :address      => %Q("@"@test),
        :comments     => nil,
        :domain       => 'test',
        :local        => %Q("@"),
        :format       => %Q("@" <"@"@test>)

    validate_case__address\
    %Q("@" <"me@me"@test>),
        :name         => "@",
        :display_name => "@",
        :address      => %Q("me@me"@test),
        :comments     => nil,
        :domain       => 'test',
        :local        => %Q("me@me"),
        :format       => %Q("@" <"me@me"@test>)

  end
  
  def test_full_stop_as_last_char_in_display_name()
  
    validate_case__address\
    %Q(Minero A. <aamine@loveruby.net>),
        :name         => "Minero A.",
        :display_name => "Minero A.",
        :address      => %Q(aamine@loveruby.net),
        :comments     => nil,
        :domain       => 'loveruby.net',
        :local        => %Q(aamine),
        :format       => %Q("me@my_place" <aamine@loveruby.net>)

  end
  
  def test_unquoted_at_char_in_name()
  
    validate_case__address\
    %Q(mikel@me.com <lindsaar@you.net>),
        :name         => "mikel@me.com",
        :display_name => "mikel@me.com",
        :address      => %Q(lindsaar@you.net),
        :comments     => nil,
        :domain       => 'you.net',
        :local        => %Q(lindsaar),
        :format       => %Q("mikel@me.com" <lindsaar@you.net>)

  end
  
  def test_special_quote_quoting_at_char_in_string
    string = 'mikel@me.com <mikel@me.com>'
    result = '"mikel@me.com" <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
  def test_special_quote_not_quoting_already_quoted_at_char_in_string
    string = '"mikel@me.com" <mikel@me.com>'
    result = '"mikel@me.com" <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
  def test_special_quote_not_quoting_something_without_an_at_char_and_quoted
    string = '"mikel" <mikel@me.com>'
    result = '"mikel" <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
  def test_special_quote_not_quoting_something_without_an_at_char_in_header
    string = 'mikel <mikel@me.com>'
    result = 'mikel <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
  def test_special_quoting_a_trailing_dot
    string = 'mikel. <mikel@me.com>'
    result = '"mikel." <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
  def test_special_quoting_a_trailing_dot_by_itself
    string = 'mikel . <mikel@me.com>'
    result = '"mikel ." <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
  def test_special_quoting_a_trailing_dot_by_itself_already_quoted
    string = '"mikel ." <mikel@me.com>'
    result = '"mikel ." <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
  def test_special_quoting_a_trailing_dot_by_itself_quoted
    string = 'mikel "." <mikel@me.com>'
    result = 'mikel "." <mikel@me.com>'
    assert_equal(result, TMail::Address.special_quote_address(string))
  end
  
end
