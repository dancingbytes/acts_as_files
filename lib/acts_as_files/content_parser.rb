# encoding: utf-8
require 'nokogiri'

module ActsAsFiles

  class ContentParser

    TEMP_TAG = "temp_tag"

    def self.parse(xpath, node_attr, content, &block)
      new(xpath, node_attr).parse(content, &block)
    end # self.parse

    def initialize(xpath, node_attr)
      @xpath, @node_attr = xpath, node_attr
    end # new

    def parse(content)

      node = ::Nokogiri::HTML::DocumentFragment.parse("<#{TEMP_TAG}>#{content}</#{TEMP_TAG}>")
      node.xpath("#{@xpath}").find_all { |node|

        unless (attr = node["#{@node_attr}"]).nil?

          unless ( (replace = yield(attr)) == false )

            node["#{@node_attr}"] = replace.url
            node["width"]  = "#{replace.width}"
            node["height"] = "#{replace.height}"

          end # unless
          
        end # unless

      } # find_all

      node.search(".//#{TEMP_TAG}").inner_html

    end # parse

  end # ContentParser

end # ActsAsFiles
