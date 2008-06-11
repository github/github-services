#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'

class REXMLTest < Test::Unit::TestCase
  def test_simple
    e = REXML::Element.new('e')
    assert_kind_of(REXML::Element, e)
    assert_nil(e.text)
    assert_nil(e.attributes['x'])
  end

  def test_normalize
    assert_equal('&amp;', REXML::Text::normalize('&'))
    assert_equal('&amp;amp;', REXML::Text::normalize('&amp;'))
    assert_equal('&amp;amp;amp;', REXML::Text::normalize('&amp;amp;'))
    assert_equal('&amp;nbsp;', REXML::Text::normalize('&nbsp;'))
  end

  def test_unnormalize
    assert_equal('&', REXML::Text::unnormalize('&amp;'))
    assert_equal('&amp;', REXML::Text::unnormalize('&amp;amp;'))
    assert_equal('&amp;amp;', REXML::Text::unnormalize('&amp;amp;amp;'))
    assert_equal('&nbsp;', REXML::Text::unnormalize('&amp;nbsp;'))
    assert_equal('&nbsp;', REXML::Text::unnormalize('&nbsp;'))  # ?
  end

  def test_text_entities
    e = REXML::Element.new('e')
    e.text = '&'
    assert_equal('<e>&amp;</e>', e.to_s)
    e.text = '&amp;'
    assert_equal('<e>&amp;amp;</e>', e.to_s)
    e.text = '&nbsp'
    assert_equal('<e>&amp;nbsp</e>', e.to_s)
    e.text = '&nbsp;'
    assert_equal('<e>&amp;nbsp;</e>', e.to_s)
    e.text = '&<;'
    assert_equal('<e>&amp;&lt;;</e>', e.to_s)
    e.text = '<>"\''
    assert_equal('<e>&lt;&gt;&quot;&apos;</e>', e.to_s)
    e.text = '<x>&amp;</x>'
    assert_equal('<e>&lt;x&gt;&amp;amp;&lt;/x&gt;</e>', e.to_s)
  end

  def test_attribute_entites
    e = REXML::Element.new('e')
    e.attributes['x'] = '&'
    assert_equal('&', e.attributes['x'])
    e.attributes['x'] = '&amp;'
    assert_equal('&', e.attributes['x']) # this one should not be escaped
    e.attributes['x'] = '&nbsp'
    assert_equal('&nbsp', e.attributes['x'])
    e.attributes['x'] = '&nbsp;'
    assert_equal('&nbsp;', e.attributes['x'])
  end
end
