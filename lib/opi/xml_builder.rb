# frozen_string_literal: true

module OPI
  ##
  #
  # class to generate simple xml strings.
  #
  #
  # ==== Example Usage
  #
  #
  #    builder = Demipos::XmlBuilder.new(:header=>%Q/<?xml version="1.0" encoding="UTF-8"?>/)
  #    builder.html do |xhtml|
  #      xhtml.head do |head|
  #        head.title 'Hello World'
  #        head.meta :name => :keywords, :content => 'hello, world'
  #        head.meta :name => :description, :content => 'hello world sample usage for XML class'
  #      end
  #      xhtml.body do |body|
  #        body.div :id => 'main' do |div_main|
  #          div_main.h1 "Hello World"
  #          div_main.p "Hello HTML world", "from XML"
  #        end
  #      end
  #    end
  #
  #    puts builder
  #
  # ==== Alternate Example Usage
  #
  #    puts Demipos::XmlBuilder.new.html {
  #      head {
  #        title 'Hello World'
  #        meta :name => :keywords, :content => 'hello, world'
  #        meta :name => :description, :content => 'hello world sample usage for XML class'
  #      }
  #
  #      body {
  #        div(:id => 'main') { |div|
  #          div.h1 "Hello World"
  #          div.p "Hello HTML world", "from XML"
  #        }
  #      }
  #    }
  #
  # ==== Acknowledgements
  # copied from
  # https://github.com/alexaandru/tiny_xml_builder
  #
  class XmlBuilder

    ##
    # create a new builder
    #
    # options...
    #
    # * +:indent_level+ starting indent level
    # * +:indent_size+  number of spaces to indent
    # * +:header+       arbitrary text at start of document
    # * +:footer+       arbitrary text at end of document
    #
    def initialize(opts = {}, &block)
      @xml          = []
      @indent_level = opts[:indent_level] || opts['indent_level'] || 0
      @indent_size  = opts[:indent_size]  || opts['indent_size']  || 2
      @header = opts[:header] || opts['header']
      @footer = opts[:footer] || opts['footer']
      @xml << @header if @header
      block && block.call(self)
      @xml << @footer if @footer
    end

    def to_s
      @xml.join("\n")
    end

    private

    def <<(xml)
      @xml << xml.to_s
    end

    def to_ary
      [to_s]
    end

    def method_missing(tag, *args, &block)
      indent     = String.new(' ' * @indent_level * @indent_size)
      attributes = args.last&.is_a?(::Hash) ? args.pop.inject(String.new){ |acc, (k, v)| acc << " #{k}=\"#{v}\"" } : ''
      if block
        @xml << format('%s<%s%s>', indent, tag, attributes)
        #@indent_level += 1; instance_eval(&block); @indent_level -= 1
        @indent_level += 1; block.call(self); @indent_level -= 1
        @xml << format('%s</%s>', indent, tag)
      elsif args.empty?
        @xml << format('%s<%s%s />', indent, tag, attributes)
      else
        args.map { |a| a && Array(a) }.flatten.each do |val|
          @xml << format('%s<%s%s>%s</%s>', indent, tag, attributes, val, tag)
        end
      end
      self
    end

    # Hide the method named +name+ in the BlankSlate class.  Don't
    # hide +instance_eval+ or any method beginning with "__".
    def self.hide(name)
      methods = instance_methods.map(&:to_sym)
      if methods.include?(name.to_sym) &&
         name !~ /^(__|instance_eval|inspect|object_id|)/
        # @hidden_methods ||= {}
        # @hidden_methods[name.to_sym] = instance_method(name)
        undef_method name
      end
    end

    instance_methods.each { |m| hide(m) }

  end
end
