require 'rubygems'
require 'json'

s = JSON.parse(File.read('amqp-0.8.json'))

# require 'pp'
# pp(s)
# exit

require 'erb'

puts ERB.new(%q[
  module AMQP
    HEADER        = <%= s['name'].dump %>.freeze
    VERSION_MAJOR = <%= s['major-version'] %>
    VERSION_MINOR = <%= s['minor-version'] %>
    PORT          = <%= s['port'] %>

    class Frame
      TYPES = [
        nil,
        <%- s['constants'].select{|c| (1..8).include? c['value'] }.each do |c| -%>
        :<%= c['name'].tr('-', '_').gsub(/^FRAME_/,'').upcase -%>,
        <%- end -%>
      ]
      FOOTER = <%= frame_end = s['constants'].find{|c| c['name'] == 'FRAME-END' }['value'] %>
    end

    RESPONSES = {
      <%- s['constants'].select{|c| c['value'] != frame_end and (200..500).include? c['value'] }.each do |c| -%>
      <%= c['value'] %> => :<%= c['name'].tr('-', '_').gsub(/^FRAME_/,'').upcase -%>,
      <%- end -%>
    }

    FIELDS = [
      <%- s['domains'].select{|d| d.first == d.last }.each do |d| -%>
      :<%= d.first -%>,
      <%- end -%>
    ]

    module Protocol
      class Class
        class << self
          FIELDS.each do |f|
            class_eval %[
              def #{f} name
                properties << [ :#{f}, name ] unless properties.include?([:#{f}, name])
                attr_accessor name
              end
            ]
          end
          
          def properties() @properties ||= [] end

          def id()   self::ID end
          def name() self::NAME end
        end

        class Method
          class << self
            FIELDS.each do |f|
              class_eval %[
                def #{f} name
                  arguments << [ :#{f}, name ] unless arguments.include?([:#{f}, name])
                  attr_accessor name
                end
              ]
            end
            
            def arguments() @arguments ||= [] end

            def parent() Protocol.const_get(self.to_s[/Protocol::(.+?)::/,1]) end
            def id()     self::ID end
            def name()   self::NAME end
          end

          def == b
            self.class.arguments.inject(true) do |eql, (type, name)|
              eql and __send__("#{name}") == b.__send__("#{name}")
            end
          end
        end
      
        def self.methods() @methods ||= {} end
      
        def self.Method(id, name)
          @_base_methods ||= {}
          @_base_methods[id] ||= ::Class.new(Method) do
            class_eval %[
              def self.inherited klass
                klass.const_set(:ID, #{id})
                klass.const_set(:NAME, :#{name.to_s})
                klass.parent.methods[#{id}] = klass
                klass.parent.methods[klass::NAME] = klass
              end
            ]
          end
        end
      end

      def self.classes() @classes ||= {} end

      def self.Class(id, name)
        @_base_classes ||= {}
        @_base_classes[id] ||= ::Class.new(Class) do
          class_eval %[
            def self.inherited klass
              klass.const_set(:ID, #{id})
              klass.const_set(:NAME, :#{name.to_s})
              Protocol.classes[#{id}] = klass
              Protocol.classes[klass::NAME] = klass
            end
          ]
        end
      end
      
      <%- s['classes'].each do |c| -%>
      class <%= c['name'].capitalize.ljust(12) %> < Class(<%= c['id'] %>, :<%= c['name'] %>); end
      <%- end -%>

      <%- s['classes'].each do |c| -%>
      class <%= c['name'].capitalize %>
        <%- c['properties'].each do |p| -%>
        <%= p['type'].ljust(10) %> :<%= p['name'].tr('-','_') %>
        <%- end if c['properties'] -%>

        <%- c['methods'].each do |m| -%>
        class <%= m['name'].capitalize.gsub(/-(.)/){ "#{$1.upcase}"}.ljust(12) %> < Method(<%= m['id'] %>, :<%= m['name'].tr('- ','_') %>); end
        <%- end -%>

        <%- c['methods'].each do |m| -%>
        class <%= m['name'].capitalize.gsub(/-(.)/){ "#{$1.upcase}"} %>
          <%- m['arguments'].each do |a| -%>
          <%- if a['domain'] -%>
          <%= s['domains'].find{|k,v| k == a['domain']}.last.ljust(10) %> :<%= a['name'].tr('- ','_') %>
          <%- else -%>
          <%= a['type'].ljust(10) %> :<%= a['name'].tr('- ','_') %>
          <%- end -%>
          <%- end if m['arguments'] -%>
        end

        <%- end -%>
      end

      <%- end -%>
    end
  end
].gsub!(/^  /,''), nil, '>-%').result(binding)
