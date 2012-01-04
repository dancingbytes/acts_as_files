# encoding: utf-8
module ActsAsFiles

  class Manager < ActsAsFiles::BaseManager

    class << self

      def append_file(obj, file_id, field)

        file_id = BSON::ObjectId(file_id) if file_id && BSON::ObjectId.legal?(file_id)

        unless file_id.is_a?(BSON::ObjectId)

          el = ::Multimedia.new do |o|
                 
            o.context_type  = obj.class.name
            o.context_id    = obj.id
            o.context_field = field.to_s
            o.file_upload   = file_id

          end # new

          return [el, true] if el.save

        else

          if (el = ::Multimedia.where({ ActsAsFiles::ID => file_id }).first).nil?
            return [nil, false]
          end

          unless el.contexted?
            
            el.context_type   = obj.class.name
            el.context_id     = obj.id
            el.context_field  = field.to_s
            el.file_upload    = el.path(:source)

            return [el, true] if el.save

          else

            # Если у файл задан контекст указанного объекта, либо
            # конекст удовлетворяет заданному объекту, но поле контекста
            # не соответствует указанному полю то создаем копию файла, указав
            # требуемые данные.
            #
            if !el.context_by?(obj) || !el.field_by?(field)

              el_copy = ::Multimedia.new do |o|
                 
                o.context_type  = obj.class.name
                o.context_id    = obj.id
                o.context_field = field.to_s
                o.file_upload   = el.path(:source)

              end # new

              return [el_copy, true] if el_copy.save

            else
              # В противном случае возвращаем данные о себе же
              return [el, true]            
            end # if

          end # unless

        end # unless

        [nil, false]
          
      end # append_file

    end # class << self

    def has_one(field, val)

      @context.class_eval %Q{

        def #{field.to_sym}=(val)

          @#{field} = unless val.is_a?(BSON::ObjectId)
            
            if BSON::ObjectId.legal?(val)
              BSON::ObjectId(val)
            elsif val.respond_to?(:id)
              val.id.to_s
            else
              val.to_s
            end  

          else
            val
          end

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

            @#{field} << unless el.is_a?(BSON::ObjectId)
            
              if BSON::ObjectId.legal?(el)
                BSON::ObjectId(el)
              elsif el.respond_to?(:id)
                el.id.to_s
              else
                el.to_s
              end

            else
              el
            end # unless

          end # each

          @#{field}

        end

      }, __FILE__, __LINE__

      super(field, val)

    end # has_many  

  end # Manager  

end # ActsAsFiles