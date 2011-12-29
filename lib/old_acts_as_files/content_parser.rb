# encoding: utf-8
module ActsAsFiles

  #
  # sc = ActsAsFiles::ContentParser.new(/([\/[0-9a-f]]+)(\/\d+)\.\w+$/, ".//img", "src")
  # sc.parse(Page.find(6).content) { |id| id > 175 ? "/asert/2/3/4/5/f/d/123.jpg" : false }
  #
  # Nokogiri::HTML::DocumentFragment.parse(Event.find(73).content).xpath('.//img').find_all
  #

  class ContentParser

    def initialize(xpath, node_attr)
      @xpath, @node_attr = xpath, node_attr
    end # new

    def parse(content)

      node = Nokogiri::HTML::DocumentFragment.parse(content)
      node.xpath("#{@xpath}").find_all { |node|

        unless (attr = node["#{@node_attr}"]).nil?

          replace = yield( ActsAsFiles::Multimedia.url_to_id(attr) )
          unless (replace == false)

            node["#{@node_attr}"] = replace.url
            node["width"]  = "#{replace.width}"
            node["height"] = "#{replace.height}"

          end # unless
          
        end # unless

      } # find_all

      node.to_html

    end # parse

  end # ContentParser

end # ActsAsFiles