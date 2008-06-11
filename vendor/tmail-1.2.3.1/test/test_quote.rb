$:.unshift File.dirname(__FILE__)
require 'test_helper'

class TestQuote < Test::Unit::TestCase
  def test_unquote_quoted_printable
    a ="=?ISO-8859-1?Q?[166417]_Bekr=E6ftelse_fra_Rejsefeber?="
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    expected = "[166417] Bekr\303\246ftelse fra Rejsefeber"
    expected.force_encoding 'utf-8' if expected.respond_to? :force_encoding
    assert_equal expected, b
  end

  def test_unquote_base64
    a ="=?ISO-8859-1?B?WzE2NjQxN10gQmVrcuZmdGVsc2UgZnJhIFJlanNlZmViZXI=?="
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    expected = "[166417] Bekr\303\246ftelse fra Rejsefeber"
    expected.force_encoding 'utf-8' if expected.respond_to? :force_encoding
    assert_equal expected, b
  end

  def test_unquote_without_charset
    a ="[166417]_Bekr=E6ftelse_fra_Rejsefeber"
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    expected = "[166417]_Bekr=E6ftelse_fra_Rejsefeber"
    expected.force_encoding 'utf-8' if expected.respond_to? :force_encoding
    assert_equal expected, b
  end
  
  def test_unqoute_multiple
    a ="=?utf-8?q?Re=3A_=5B12=5D_=23137=3A_Inkonsistente_verwendung_von_=22Hin?==?utf-8?b?enVmw7xnZW4i?=" 
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    expected = "Re: [12] #137: Inkonsistente verwendung von \"Hinzuf\303\274gen\""
    expected.force_encoding 'utf-8' if expected.respond_to? :force_encoding
    assert_equal expected, b
  end

  def test_unqoute_in_the_middle
    a ="Re: Photos =?ISO-8859-1?Q?Brosch=FCre_Rand?=" 
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    expected = "Re: Photos Brosch\303\274re Rand"
    expected.force_encoding 'utf-8' if expected.respond_to? :force_encoding
    assert_equal expected, b
  end

  def test_unqoute_iso
    a ="=?ISO-8859-1?Q?Brosch=FCre_Rand?=" 
    b = TMail::Unquoter.unquote_and_convert_to(a, 'iso-8859-1')
    expected = "Brosch\374re Rand" 
    expected.force_encoding 'iso-8859-1' if expected.respond_to? :force_encoding 
    assert_equal expected, b
  end
  
  def test_quote_multibyte_chars
    original = "\303\246 \303\270 and \303\245"
    unquoted = TMail::Unquoter.unquote_and_convert_to(original, nil)
    original.force_encoding 'utf-8' if original.respond_to? :force_encoding
    unquoted.force_encoding 'utf-8' if unquoted.respond_to? :force_encoding
    assert_equal unquoted, original
  end

  # test an email that has been created using \r\n newlines, instead of
  # \n newlines.
  def test_email_quoted_with_0d0a
    mail = TMail::Mail.parse(IO.read("#{File.dirname(__FILE__)}/fixtures/raw_email_quoted_with_0d0a"))
    assert_match %r{Elapsed time}, mail.body
  end

  def test_email_with_partially_quoted_subject
    mail = TMail::Mail.parse(IO.read("#{File.dirname(__FILE__)}/fixtures/raw_email_with_partially_quoted_subject"))
    expected = "Re: Test: \"\346\274\242\345\255\227\" mid \"\346\274\242\345\255\227\" tail"
    expected.force_encoding 'utf-8' if expected.respond_to? :force_encoding
    assert_equal expected, mail.subject
  end

  def test_decode
    encoded, decoded = expected_base64_strings
    assert_equal decoded, TMail::Base64.decode(encoded)
  end

  def test_encode
    encoded, decoded = expected_base64_strings
    assert_equal encoded, TMail::Base64.encode(decoded)
  end

  private

  def expected_base64_strings
      if RUBY_VERSION < '1.9'
        options = "r" 
      else
        options = "r:ASCII-8BIT"
      end
      encoded = File.open("#{File.dirname(__FILE__)}/fixtures/raw_base64_encoded_string", options) {|f| f.read }
      decoded = File.open("#{File.dirname(__FILE__)}/fixtures/raw_base64_decoded_string", options) {|f| f.read }
      [encoded, decoded]
  end

end
