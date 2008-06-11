require 'test_helper'
require 'tmail/loader'
require 'tmail/port'
require 'fileutils'

class FilePortTester < Test::Unit::TestCase
  include FileUtils

  def setup
    rm_rf 'tmp'
    mkdir 'tmp'
    5.times do |n|
      File.open('tmp/' + n.to_s, 'w') {|f|
        f.puts "file #{n}"
      }
    end
  end

  def teardown
    rm_rf 'tmp'
  end

  def test_s_new
    port = TMail::FilePort.new('tmp/1')
    assert_instance_of TMail::FilePort, port
  end

  def test_inspect
    port = TMail::FilePort.new('tmp/1')
    port.inspect
  end

  def test_EQUAL   # ==
    port = TMail::FilePort.new('tmp/1')
    assert_equal port, port
    p2 = TMail::FilePort.new('tmp/1')
    assert_equal port, p2
  end

  def test_eql?
    port = TMail::FilePort.new('tmp/1')
    assert_equal true, port.eql?(port)
    p2 = TMail::FilePort.new('tmp/1')
    assert_equal true, port.eql?(p2)
  end

  def test_hash
    port = TMail::FilePort.new('tmp/1')
    assert_equal port.hash, port.hash
    p2 = TMail::FilePort.new('tmp/1')
    assert_equal port.hash, p2.hash
  end

  def test_filename
    port = TMail::FilePort.new('tmp/1')
    assert_not_nil port.filename
    assert_equal File.expand_path('tmp/1'), port.filename
    assert_equal File.expand_path('tmp/1'), port.filename

    port = TMail::FilePort.new('tmp/2')
    assert_not_nil port.filename
    assert_equal File.expand_path('tmp/2'), port.filename
    assert_equal File.expand_path('tmp/2'), port.filename
  end

  def test_ident
    ports = []
    5.times do |n|
      ports.push TMail::FilePort.new("tmp/#{n}")
    end

    until ports.empty? do
      base = ports.shift
      ports.each do |other|
        assert_not_equal base.ident, other.ident
      end
    end
  end

  def test_size
    5.times do |n|
      port = TMail::FilePort.new("tmp/#{n}")
      assert_equal File.size("tmp/#{n}"), port.size
    end
  end

  def test_ropen
    port = TMail::FilePort.new("tmp/1")
    f = port.ropen
    assert_instance_of File, f
    assert_equal false, f.closed?
    assert_equal 'f', f.read(1)
    f.close

    f = nil
    port.ropen {|ff|
      assert_instance_of File, ff
      assert_equal false, ff.closed?
      assert_equal 'f', ff.read(1)
      f = ff
    }
    assert_equal true, f.closed?

    assert_raises( Errno::ENOENT ) {
      TMail::FilePort.new('tmp/100').ropen
    }
  end

  def test_wopen
    port = TMail::FilePort.new('tmp/1')
    f = port.wopen
    assert_instance_of File, f
    assert_equal false, f.closed?
    f.puts 'ok'
    f.close

    f = nil
    port.wopen {|ff|
      assert_instance_of File, ff
      assert_equal false, ff.closed?
      ff.puts 'ok'
      f = ff
    }
    assert_equal true, f.closed?

    TMail::FilePort.new('tmp/100').wopen {|ff| }
  end

  def test_aopen
    port = TMail::FilePort.new('tmp/1')
    size = port.size
    f = port.aopen
    assert_instance_of File, f
    assert_equal false, f.closed?
    f.print 'N'
    f.close
    assert_equal size + 1, port.size
    port.ropen {|ff|
      assert_equal 'f', ff.read(1)
    }

    f = nil
    port.aopen {|ff|
      assert_instance_of File, ff
      assert_equal false, ff.closed?
      ff.print 'N'
      f = ff
    }
    assert_equal true, f.closed?
    assert_equal size + 1 + 1, port.size
    port.ropen {|ff|
      assert_equal 'f', ff.read(1)
    }

    TMail::FilePort.new('tmp/100').aopen {|ff| }
  end

  def test_read_all
    5.times do |n|
      port = TMail::FilePort.new("tmp/#{n}")
      assert_equal readall("tmp/#{n}"), port.read_all
    end
  end

  def test_copy_to
    src = TMail::FilePort.new('tmp/1')
    dest = TMail::FilePort.new('tmp/10')
    src.copy_to dest
    assert_equal readall('tmp/1'), readall('tmp/10')
  end

  def test_move_to
    src = TMail::FilePort.new('tmp/1')
    str = src.read_all
    dest = TMail::FilePort.new('tmp/10')
    src.move_to dest
    assert_equal str, readall('tmp/10')
    assert_raises( Errno::ENOENT ) { src.ropen }
  end

  def test_remove
    port = TMail::FilePort.new('tmp/1')
    port.remove
    assert_raises(Errno::ENOENT) {
      port.ropen
    }

    port = TMail::FilePort.new('tmp/100')
    assert_raises(Errno::ENOENT) {
      port.remove
    }
  end

  def readall(fname)
    File.open(fname) {|f|
      return f.read
    }
  end
end

class StringPortTester < Test::Unit::TestCase
  def test_s_new
    port = TMail::StringPort.new
    assert_instance_of TMail::StringPort, port
  end

  def test_EQUAL   # ==
    port = TMail::StringPort.new(str = '')
    port2 = TMail::StringPort.new(str)
    other = TMail::StringPort.new
    assert_equal port, port
    assert_equal port, port2
    assert_not_equal port, other
  end

  def test_eql?
    port = TMail::StringPort.new(str = '')
    port2 = TMail::StringPort.new(str)
    other = TMail::StringPort.new
    assert_equal true, port.eql?(port)
    assert_equal true, port.eql?(port2)
    assert_equal false, port.eql?(other)
  end

  def test_hash
    port = TMail::StringPort.new(str = '')
    port2 = TMail::StringPort.new(str)
    other = TMail::StringPort.new
    assert_equal port.hash, port.hash
    assert_equal port.hash, port2.hash
    # assert_not_equal port.hash, other.hash
  end

  def test_string
    port = TMail::StringPort.new(str = '')
    assert_same str, port.string
    assert_same port.string, port.string
  end

  def test_to_s
    port = TMail::StringPort.new(str = 'abc')
    assert_equal str, port.to_s
    port.to_s.concat 'XXX'
    assert_equal str, port.to_s
  end

  def test_inspect
    TMail::StringPort.new.inspect
    TMail::StringPort.new('abc').inspect
  end

  def test_size
    port = TMail::StringPort.new(str = 'abc')
    assert_equal str.size, port.size
  end

  def test_ropen
    port = TMail::StringPort.new(str = 'abc')
    f = port.ropen
    assert_equal false, f.closed?
    assert_equal 'a', f.read(1)
    f.close

    port.ropen {|ff|
      assert_equal false, ff.closed?
      assert_equal 'a', ff.read(1)
      f = ff
    }
    assert_equal true, f.closed?
  end

  def test_wopen
    port = TMail::StringPort.new(str = 'abc')
    f = port.wopen
    assert_equal false, f.closed?
    f.print 'N'
    f.close
    assert_equal 'N', port.read_all

    port.wopen {|ff|
      assert_equal false, ff.closed?
      ff.print 'NN'
      f = ff
    }
    assert_equal true, f.closed?
    assert_equal 'NN', port.read_all
  end

  def test_aopen
    port = TMail::StringPort.new(str = 'abc')
    f = port.aopen
    assert_equal false, f.closed?
    f.print 'N'
    f.close
    assert_equal 'abcN', port.read_all

    port.aopen {|ff|
      assert_equal false, ff.closed?
      ff.print 'F'
      f = ff
    }
    assert_equal true, f.closed?
    assert_equal 'abcNF', port.read_all
  end

  include FileUtils

  def test_copy_to
    src = TMail::StringPort.new('abc')
    dest = TMail::StringPort.new
    src.copy_to dest
    assert_equal src.read_all, dest.read_all
    assert_not_equal src.string.object_id, dest.string.object_id
  end

  def test_move_to
    src = TMail::StringPort.new(str = 'abc')
    dest = TMail::StringPort.new
    src.move_to dest
    assert_same str, dest.string
    assert_raises(Errno::ENOENT) {
      src.ropen
    }
  end

  def test_remove
    port = TMail::StringPort.new(str = 'abc')
    port.remove
    assert_raises(Errno::ENOENT) {
      port.ropen
    }
  end
end

class MhPortTester < Test::Unit::TestCase
  include FileUtils

  def setup
    rm_rf 'tmp'
    mkdir 'tmp'
    3.times do |n|
      File.open( "tmp/#{n}", 'w' ) {|f|
        f.puts 'From: Minero Aoki <aamine@loveruby.net>'
        f.puts "Subject: test file #{n}"
        f.puts
        f.puts 'This is body.'
      }
    end
  end

  def teardown
    rm_rf 'tmp'
  end

  def test_flags
    port = TMail::MhPort.new('tmp/1')
    assert_equal false, port.flagged?
    port.flagged = true
    assert_equal true, port.flagged?

    assert_equal false, port.replied?
    port.replied = true
    assert_equal true, port.replied?

    assert_equal false, port.seen?
    port.seen = true
    assert_equal true, port.seen?

    port = TMail::MhPort.new('tmp/1')
    assert_equal true, port.flagged?
    assert_equal true, port.replied?
    assert_equal true, port.seen?

    port = TMail::MhPort.new('tmp/1')
    port.flagged = false
    port.replied = false
    port.seen = false

    port = TMail::MhPort.new('tmp/1')
    assert_equal false, port.flagged?
    assert_equal false, port.replied?
    assert_equal false, port.seen?
  end
end

class MaildirPortTester < Test::Unit::TestCase
  include FileUtils

  def setup
    rm_rf 'tmp'
    mkdir 'tmp'
    3.times do |n|
      File.open( "tmp/000.00#{n}.a", 'w' ) {|f|
        f.puts 'From: Minero Aoki <aamine@loveruby.net>'
        f.puts "Subject: test file #{n}"
        f.puts
        f.puts 'This is body.'
      }
    end
  end

  def teardown
    rm_rf 'tmp'
  end

  def test_flags
    port = TMail::MaildirPort.new('tmp/000.001.a')

    assert_equal false, port.flagged?
    port.flagged = true
    assert_equal true, port.flagged?

    assert_equal false, port.replied?
    port.replied = true
    assert_equal true, port.replied?

    assert_equal false, port.seen?
    port.seen = true
    assert_equal true, port.seen?

    port = TMail::MaildirPort.new(port.filename)
    assert_equal true, port.flagged?
    assert_equal true, port.replied?
    assert_equal true, port.seen?

    port = TMail::MaildirPort.new(port.filename)
    port.flagged = false
    port.replied = false
    port.seen = false

    port = TMail::MaildirPort.new(port.filename)
    assert_equal false, port.flagged?
    assert_equal false, port.replied?
    assert_equal false, port.seen?
  end
end
