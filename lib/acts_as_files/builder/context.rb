# encoding: utf-8
module ActsAsFiles

  module Builder

    class Context

      def initialize

        @one  = {}
        @many = {}

      end # new  

      def compile

        {
          :one  =>  @one,
          :many =>  @many
        }

      end # compile

      private

      def method_missing(name, *args, &block)
      end # method_missing

      def has_one(name, &block)

        r = ::ActsAsFiles::Builder::ContextParams.new
        r.instance_eval &block if block_given?
        @one[name.to_s] = r.compile

      end # has_one

      def has_many(name, &block)

        r = ::ActsAsFiles::Builder::ContextParams.new
        r.instance_eval &block if block_given?
        @many[name.to_s] = r.compile

      end # has_many

    end # Context
  

    class ContextParams

      def initialize
        @marks = {}
      end # new
      
      def compile

        {
          :default    => @default,
          :marks      => @marks,
          :parse_from => @parse_from
        }

      end # compile

      private

      def method_missing(name, *args, &block)
      end # method_missing

      def parse_from(name = nil)
        @parse_from = name.to_sym if name
      end # parse_from 

      def default(size = nil, &block)

        if block_given?
          @default = block
        elsif size.is_a?(String) && !size.empty?
          @default = size
        end  
        
      end # default  

      def copies(mark, size = nil, &block)

        if block_given?
          @marks[mark.to_s] = block
        elsif size.is_a?(String) && !size.empty?
          @marks[mark.to_s] = size
        end  

      end # copies

    end # ContextParams

  end # Builder
  
end # ActsAsFiles