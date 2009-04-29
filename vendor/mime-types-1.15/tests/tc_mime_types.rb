#! /usr/bin/env ruby
#--
# MIME::Types for Ruby
#   http://rubyforge.org/projects/mime-types/
#   Copyright 2003 - 2005 Austin Ziegler.
#   Licensed under a MIT-style licence.
#
# $Id: tc_mime_types.rb,v 1.2 2006/02/12 21:27:22 austin Exp $
#++
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../lib") if __FILE__ == $0

require 'mime/types'
require 'test/unit'

class TestMIME__Types < Test::Unit::TestCase #:nodoc:
  def test_s_AREF # singleton method '[]'
    text_plain = MIME::Type.new('text/plain') do |t|
      t.encoding = '8bit'
      t.extensions = ['asc', 'txt', 'c', 'cc', 'h', 'hh', 'cpp', 'hpp',
        'dat', 'hlp']
    end
    text_plain_vms = MIME::Type.new('text/plain') do |t|
      t.encoding = '8bit'
      t.extensions = ['doc']
      t.system = 'vms'
    end
    text_vnd_fly = MIME::Type.new('text/vnd.fly')
    assert_equal(MIME::Types['text/plain'].sort,
                 [text_plain, text_plain_vms].sort)

    tst_bmp = MIME::Types["image/x-bmp"] +
      MIME::Types["image/vnd.wap.wbmp"] + MIME::Types["image/x-win-bmp"]

    assert_equal(tst_bmp.sort, MIME::Types[/bmp$/].sort)
    assert_nothing_raised {
      MIME::Types['image/bmp'][0].system = RUBY_PLATFORM
    }
    assert_equal([MIME::Type.from_array('image/x-bmp', ['bmp'])],
                 MIME::Types[/bmp$/, { :platform => true }])

    assert(MIME::Types['text/vnd.fly', { :complete => true }].empty?)
    assert(!MIME::Types['text/plain', { :complete => true} ].empty?)
  end

  def test_s_add
    assert_nothing_raised do
      @eruby = MIME::Type.new("application/x-eruby") do |t|
        t.extensions = "rhtml"
        t.encoding = "8bit"
      end

      MIME::Types.add(@eruby)
    end

    assert_equal(MIME::Types['application/x-eruby'], [@eruby])
  end

  def test_s_type_for
    assert_equal(MIME::Types.type_for('xml').sort, [ MIME::Types['text/xml'], MIME::Types['application/xml'] ].sort)
    assert_equal(MIME::Types.type_for('gif'), MIME::Types['image/gif'])
    assert_nothing_raised do
      MIME::Types['image/gif'][0].system = RUBY_PLATFORM
    end
    assert_equal(MIME::Types.type_for('gif', true), MIME::Types['image/gif'])
    assert(MIME::Types.type_for('zzz').empty?)
  end

  def test_s_of
    assert_equal(MIME::Types.of('xml').sort, [ MIME::Types['text/xml'], MIME::Types['application/xml'] ].sort)
    assert_equal(MIME::Types.of('gif'), MIME::Types['image/gif'])
    assert_nothing_raised do
      MIME::Types['image/gif'][0].system = RUBY_PLATFORM
    end
    assert_equal(MIME::Types.of('gif', true), MIME::Types['image/gif'])
    assert(MIME::Types.of('zzz').empty?)
  end
end
