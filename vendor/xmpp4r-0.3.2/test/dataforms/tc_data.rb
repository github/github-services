#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require 'xmpp4r/dataforms'
include Jabber

class DataFormsTest < Test::Unit::TestCase

  def test_create_defaults
    v = Dataforms::XDataTitle.new
    assert_nil(v.title)
    assert_equal("", v.to_s)

    v = Dataforms::XDataInstructions.new
    assert_nil(v.instructions)
    assert_equal("", v.to_s)

    v = Dataforms::XDataField.new
    assert_nil(v.label)
    assert_nil(v.var)
    assert_nil(v.type)
    assert_equal(false, v.required?)
    assert_equal([], v.values)
    assert_equal({}, v.options)

    v = Dataforms::XData.new
    assert_equal([], v.fields)
    assert_nil(v.type)
  end

  def test_create
    v = Dataforms::XDataTitle.new "This is the title"
    assert_equal("This is the title",v.title)
    assert_equal("This is the title", v.to_s)

    v = Dataforms::XDataInstructions.new "Instructions"
    assert_equal("Instructions",v.instructions)
    assert_equal("Instructions", v.to_s)

    f = Dataforms::XDataField.new "botname", :text_single
    assert_nil(f.label)
    assert_equal("botname", f.var)
    assert_equal(:text_single, f.type)
    assert_equal(false, f.required?)
    assert_equal([], f.values)
    assert_equal({}, f.options)
    f.label = "The name of your bot"
    assert_equal("The name of your bot", f.label)
    [:boolean, :fixed, :hidden, :jid_multi, :jid_single,
     :list_multi, :list_single, :text_multi, :text_private,
     :text_single].each do |type|
      f.type = type
      assert_equal(type, f.type)
    end
    f.type = :wrong_type
    assert_nil(f.type)
    f.required= true
    assert_equal(true, f.required?)
    f.values = ["the value"]
    assert_equal(["the value"], f.values)
    f.options = { "option 1" => "Label 1", "option 2" => "Label 2", "option 3" => nil }
    assert_equal({ "option 1" => "Label 1", "option 2" => "Label 2", "option 3" => nil }, f.options)


    f = Dataforms::XDataField.new "test", :text_single
    v = Dataforms::XData.new :form
    assert_equal([], v.fields)
    assert_equal(:form, v.type)
    [:form, :result, :submit, :cancel].each do |type|
      v.type = type
      assert_equal(type, v.type)
    end
    v.add f
    assert_equal(f, v.field('test'))
    assert_nil(v.field('wrong field'))
    assert_equal([f], v.fields)
   end

end
