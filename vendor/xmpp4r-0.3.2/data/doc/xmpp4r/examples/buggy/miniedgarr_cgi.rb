#!/usr/bin/env ruby
#
# cp /usr/local/share/psi/iconsets/roster/lightbulb/{away,online,offline,xa,chat,dnd}.png .

$:.unshift '../lib'

require 'GD'
require 'cgi'
require 'digest/md5'
        
require 'rexml/document'

require 'xmpp4r'
require 'xmpp4r/iqqueryroster'

# Handle CGI parameters
cgi = CGI.new
jid = Jabber::JID.new(cgi['jid']).strip
jidhash = cgi['hash']
transparency = (cgi['transparency'] == 'true')

# Create data

roster = Jabber::IqQueryRoster.new
presences = {}

# Load state

doc = REXML::Document.new(File.new('edgarrstate.xml'))

doc.root.each_element { |e|
  if (e.name == 'query') && (e.namespace == 'jabber:iq:roster')
    roster.import(e)
  elsif e.name == 'presence'
    pres = Jabber::Presence.new.import(e)

    if (pres.from.strip == jid) || (Digest::MD5.hexdigest(pres.from.strip.to_s) == jidhash)
      if (jid == '') && !jidhash.nil?
        jid = pres.from.strip
      end
      presences[pres.from] = pres
    end
  end
}

resources = (presences.size < 1) ? 1 : presences.size


class BannerTable
  def initialize
    @lines = []
  end

  def last
    @lines[@lines.size - 1]
  end
  
  def add_line
    @lines.push(BannerLine.new)
  end

  def paint
    width = 0
    height = 0
    @lines.each do |line|
      if width < line.w
        width = line.w
      end
      height += line.h
    end
    
    gd = GD::Image.new(width + 6, height + 6)
    white = gd.colorAllocate(255,255,255)
    black = gd.colorAllocate(0,0,0)       

    gd.fill(0, 0, black)
    gd.interlace = true
    gd.rectangle(0,0,width + 5,height + 5,white)
    y = 2

    @lines.each do |line|
      line.paint(gd, 3, y + (line.h / 2))
      y += line.h
    end
    
    gd
  end
end

class BannerLine
  def initialize
    @items = []
  end

  def add(type, text)
    @items.push(BannerItem.new(type, text))
  end

  def w
    w = 1
    @items.each do |item|
      w += item.w
    end
    w
  end

  def h
    h = 0
    @items.each do |item|
      if h < item.h
        h = item.h
      end
    end
    h
  end

  def paint(gd, x_start, y_center)
    x = x_start
    @items.each do |item|
      item.paint(gd, x, y_center - (item.h / 2))
      x += item.w
    end
  end
end

class BannerItem
  def initialize(type, text)
    @type = type
    @text = text
  end

  def w
    if @type.kind_of?(GD::Font)
      (@type.width * @text.size) + 2
    elsif @type.kind_of?(GD::Image)
      @type.width + 2
    end
  end

  def h
    if @type.kind_of?(GD::Font) || @type.kind_of?(GD::Image)
      @type.height + 2
    end
  end

  def paint(gd, x, y)
    if @type.kind_of?(GD::Font) && (@text.size > 0)
      gd.string(@type, x + 1, y + 1, @text, gd.colorAllocate(255,255,255))
    elsif @type.kind_of?(GD::Image)
      type = @type.to_paletteImage(false, 256)
      type.copy(gd, x + 1, y + 1, 0, 0, type.height, type.height)
    end
  end
end

# Paint the image

table = BannerTable.new
table.add_line

# Put JID at top
if roster[jid.strip].nil?
  iname = 'Unknown'
else
  iname = roster[jid.strip].iname.to_s
end
table.last.add(GD::Font::MediumFont, iname == '' ? jid.to_s : iname)

if (presences.size < 1)
  table.add_line
  table.last.add(GD::Font::SmallFont, 'Unavailable')
else
  presences.each { |jid,pres|
    show = pres.show.to_s
    if pres.type == :unavailable
      show = 'offline'
    elsif pres.show.nil?
      show = 'online'
    end

    table.add_line
    table.last.add(GD::Image.newFromPng(File.new("miniedgarr_bulbs/#{show}.png")), nil)
    prio = pres.priority.nil? ? 0 : pres.priority
    table.last.add(GD::Font::SmallFont, "#{pres.from.resource} (#{prio})")
    table.add_line
    table.last.add(GD::Font::TinyFont, pres.status.to_s.strip)
  }
end

# Convert the image to PNG and print it on standard output
print "Content-type: image/png\r\n\r\n"
table.paint.png STDOUT
