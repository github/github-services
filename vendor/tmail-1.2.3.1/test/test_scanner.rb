$:.unshift File.dirname(__FILE__)
require 'test_helper'
require 'tmail/scanner'
require 'test/unit'

class ScannerTester < Test::Unit::TestCase
  DEBUG = false

  def do_test( scantype, str, ok, cmtok )
    scanner = TMail::Scanner.new( str, scantype, comments = [] )
    scanner.debug = DEBUG

    idx = 0
    scanner.scan do |sym, val|
      if sym then
        assert_equal ok.shift, [sym, val],       "index=#{idx}"
      else
        assert_equal [false, '$'], [sym, val],   "$end (index=#{idx})"
      end
      idx += 1
    end
    assert_equal [], ok

    comments.each_with_index do |val, i|
      assert_equal cmtok.shift, val,  "index=#{i}"
    end
  end

  def test_atommode
    do_test :ADDRESS,
    'Capital CAPITAL word from id by with a0000',
        [
          [:ATOM, 'Capital'],
          [:ATOM, 'CAPITAL'],
          [:ATOM, 'word'],
          [:ATOM, 'from'],
          [:ATOM, 'id'],
          [:ATOM, 'by'],
          [:ATOM, 'with'],
          [:ATOM, 'a0000']
        ],
        []

    do_test :ADDRESS,
    '(comment) (nested (comment) (again)) (a(b(c(d(e)))))',
        [
        ],
        [
          'comment',
          'nested (comment) (again)',
          'a(b(c(d(e))))'
        ]

    do_test :ADDRESS,
    '=?iso-2022-jp?B?axaxax?=',
        [
          [:ATOM, '=?iso-2022-jp?B?axaxax?=']
        ],
        []

    word = 'abcdefghijklmnopqrstuvwxyz' +
           'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
           '0123456789' +
           %q[_#!$%&`'*+-{|}~^/=?]
    do_test :ADDRESS, word,
        [
          [:ATOM, word]
        ],
        []

    do_test :ADDRESS,
    "    \t\t\r\n \n\r\n  \r \n     atom",
        [
          [:ATOM, 'atom']
        ],
        []
  end

  def test_tokenmode
    do_test :CTYPE,
    'text/html; charset=iso-2022-jp',
        [
          [:TOKEN, 'text'],
          ['/'   , '/'],
          [:TOKEN, 'html'],
          [';'   , ';'],
          [:TOKEN, 'charset'],
          ['='   , '='],
          [:TOKEN, 'iso-2022-jp']
        ],
        []

    do_test :CTYPE,
    'Text/Plain; Charset=ISO-2022-JP',
        [
          [:TOKEN, 'Text'],
          ['/'   , '/'],
          [:TOKEN, 'Plain'],
          [';'   , ';'],
          [:TOKEN, 'Charset'],
          ['='   , '='],
          [:TOKEN, 'ISO-2022-JP'],
        ],
        []

    do_test :CTYPE,
    'm_m/s_s; k_k=v_v',
        [
          [:TOKEN, 'm_m'],
          ['/'   , '/'],
          [:TOKEN, 's_s'],
          [';'   , ';'],
          [:TOKEN, 'k_k'],
          ['='   , '='],
          [:TOKEN, 'v_v'],
        ],
        []

    word = 'abcdefghijklmnopqrstuvwxyz' +
           'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
           '0123456789' +
           %q[_#!$%&`'*+-{|}~^.]
    do_test :CTYPE, word,
        [
          [:TOKEN, word]
        ],
        []
  end

  def test_received
    do_test :RECEIVED,
    'from From by By via Via with With id Id for For',
        [
          [:FROM, 'from'],
          [:FROM, 'From'],
          [:BY,   'by'],
          [:BY,   'By'],
          [:VIA,  'via'],
          [:VIA,  'Via'],
          [:WITH, 'with'],
          [:WITH, 'With'],
          [:ID,   'id'],
          [:ID,   'Id'],
          [:FOR,  'for'],
          [:FOR,  'For']
        ],
        []

    str = <<EOS
from hoyogw.netlab.co.jp (daemon@hoyogw.netlab.co.jp [202.218.249.220])
by serv1.u-netsurf.ne.jp (8.8.8/3.6W-2.66(99/03/09))
with ESMTP id RAA10692 for <aamine@dp.u-netsurf.ne.jp>;
Thu, 18 Mar 1999 17:35:23 +0900 (JST)
EOS
    ok = [
        [ :FROM , 'from'      ],
        [ :ATOM , 'hoyogw'    ],
        [ '.'   , '.'         ],
        [ :ATOM , 'netlab'    ],
        [ '.'   , '.'         ],
        [ :ATOM , 'co'        ],
        [ '.'   , '.'         ],
        [ :ATOM , 'jp'        ],
        [ :BY   , 'by'        ],
        [ :ATOM , 'serv1'     ],
        [ '.'   , '.'         ],
        [ :ATOM , 'u-netsurf' ],
        [ '.'   , '.'         ],
        [ :ATOM , 'ne'        ],
        [ '.'   , '.'         ],
        [ :ATOM , 'jp'        ],
        [ :WITH , 'with'      ],
        [ :ATOM , 'ESMTP'     ],
        [ :ID   , 'id'        ],
        [ :ATOM , 'RAA10692'  ],
        [ :FOR  , 'for'       ],
        [ '<'   , '<'         ],
        [ :ATOM , 'aamine'    ],
        [ '@'   , '@'         ],
        [ :ATOM , 'dp'        ],
        [ '.'   , '.'         ],
        [ :ATOM , 'u-netsurf' ],
        [ '.'   , '.'         ],
        [ :ATOM , 'ne'        ],
        [ '.'   , '.'         ],
        [ :ATOM , 'jp'        ],
        [ '>'   , '>'         ],
        [ ';'   , ';'         ],
        [ :ATOM , 'Thu'       ],
        [ ','   , ','         ],
        [ :DIGIT, '18'        ],
        [ :ATOM , 'Mar'       ],
        [ :DIGIT, '1999'      ],
        [ :DIGIT, '17'        ],
        [ ':'   , ':'         ],
        [ :DIGIT, '35'        ],
        [ ':'   , ':'         ],
        [ :DIGIT, '23'        ],
        [ :ATOM , '+0900'     ]
    ]
    cmtok = [
      'daemon@hoyogw.netlab.co.jp [202.218.249.220]',
      '8.8.8/3.6W-2.66(99/03/09)',
      'JST'
    ]

    do_test :RECEIVED, str, ok, cmtok
  end
end
