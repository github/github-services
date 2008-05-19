# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'rexml/document'
require 'rexml/parsers/xpathparser'
require 'rexml/source'

# Turn $VERBOSE off to suppress warnings about redefinition
oldverbose = $VERBOSE
$VERBOSE = false

# REXML module. This file only adds the following methods to the REXML module, to
# ease the coding:
# * replace_element_text
# * first_element
# * first_element_text
# * typed_add
# * import
# * self.import
# * delete_elements
#
# Further definitions are just copied from REXML out of Ruby-1.8.4 to solve issues
# with REXML in Ruby-1.8.2.
#
# The redefinitions of Text::normalize and Attribute#initialize address an issue
# where entities in element texts and attributes were not escaped. This modifies
# the behavious of REXML a bit but Sean Russell intends a similar behaviour for
# the future of REXML.
module REXML
  # this class adds a few helper methods to REXML::Element
  class Element
    ##
    # Replaces or add a child element of name <tt>e</tt> with text <tt>t</tt>.
    def replace_element_text(e, t)
      el = first_element(e)
      if el.nil?
        el = REXML::Element::new(e)
        add_element(el)
      end
      if t
        el.text = t
      end
      self
    end

    ##
    # Returns first element of name <tt>e</tt>
    def first_element(e)
      each_element(e) { |el| return el }
      return nil
    end

    ##
    # Returns text of first element of name <tt>e</tt>
    def first_element_text(e)
      el = first_element(e)
      if el
        return el.text
      else
        return nil
      end
    end

    # This method does exactly the same thing as add(), but it can be
    # overriden by subclasses to provide on-the-fly object creations.
    # For example, if you import a REXML::Element of name 'plop', and you
    # have a Plop class that subclasses REXML::Element, with typed_add you
    # can get your REXML::Element to be "magically" converted to Plop.
    def typed_add(e)
      add(e)
    end

    ##
    # import this element's children and attributes
    def import(xmlelement)
      if @name and @name != xmlelement.name
        raise "Trying to import an #{xmlelement.name} to a #{@name} !"
      end
      add_attributes(xmlelement.attributes.clone)
      @context = xmlelement.context
      xmlelement.each do |e|
        if e.kind_of? REXML::Element
          typed_add(e.deep_clone)
        else # text element, probably.
          add(e.clone)
        end
      end
      self
    end

    def self.import(xmlelement)
      self.new(xmlelement.name).import(xmlelement)
    end

    ##
    # Deletes one or more children elements,
    # not just one like REXML::Element#delete_element
    def delete_elements(element)
      while(delete_element(element)) do end
    end
  end
end

# very dirty fix for the :progress problem in REXML from Ruby 1.8.3
# http://www.germane-software.com/projects/rexml/ticket/34
# the fix proposed in REXML changeset 1145 only fixes this for pipes, not for
# TCP sockets, so we have to keep this.
module REXML
  class IOSource
    def position
      0
    end

    def current_line
      [0, 0, ""]
    end
  end
end

# Restore the old $VERBOSE setting
$VERBOSE = oldverbose

