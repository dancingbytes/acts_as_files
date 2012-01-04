# encoding: utf-8
module ActsAsFiles

  class Manager < ActsAsFiles::BaseManager

    class << self

      def append_file(obj, file_id, field)
        [nil, false]
      end # append_file

    end # class << self 

    def has_one(field, val)

      @context.class_eval %Q{

        def #{field.to_sym}=(val)
          @#{field} = (val && val.respond_to?(:id) ? val.id : val.to_s)
        end

      }, __FILE__, __LINE__

      super(field, val)

    end # has_one  

    def has_many(field, val)

      @context.class_eval %Q{

        def #{field.to_sym}=(val)

          val = [val] unless val.is_a?(Array)

          @#{field} = []
          val.compact.uniq.each do |el|
            @#{field} << (el && el.respond_to?(:id) ? el.id : el.to_s)
          end # each

          @#{field}

        end

      }, __FILE__, __LINE__

      super(field, val)

    end # has_many  

  end # Manager

end # ActsAsFiles