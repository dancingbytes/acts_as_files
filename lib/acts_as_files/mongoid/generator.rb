# encoding: utf-8
module ActsAsFiles

  class Generator

    def initialize(context, opts = {})
      
      @context, @opts = context, opts
      puts "opts: #{opts}"
      init

    end # new

    private

    def init

      (@opts[:one] || {}).each { |field, val|        
        has_one(field, val)
      }

      (@opts[:many] || {}).each { |field, val|
        has_many(field, val)
      }

    end # init

    def has_one(field, val)

#      str = ""
#      val.each {
#        str << ""
#      }

#        set_callback(:save, :after) do |document|
#          OLOLOLOLOLO.make_me_sexy(self, #{field}, params)
#        end

      @context.class_eval %Q{

        def #{field.to_sym}(*args)
          Multimedia.by_field("#{field}").dimentions(*args).first
        end
        
        def #{field.to_sym}=(val)

          @#{field} = unless val.is_a?(BSON::ObjectId)
            
            if BSON::ObjectId.legal?(val)
              BSON::ObjectId(val)
            elsif val.respond_to?(:id)
              val.id
            else
              val.to_s
            end  

          else
            val  
          end

        end

      }, __FILE__, __LINE__

    end # has_one  

    def has_many(field, val)

      @context.class_eval %Q{

        def #{field.to_sym}(*args)
          Multimedia.by_field("#{field}").dimentions(*args).asc(:position)
        end

        def #{field.to_sym}=(val)

          val = [val] unless val.is_a?(Array)

          @#{field} = []
          val.compact.uniq.each do |el|

            @#{field} << unless val.is_a?(BSON::ObjectId)
            
              if BSON::ObjectId.legal?(val)
                BSON::ObjectId(val)
              elsif val.respond_to?(:id)
                val.id
              else
                val.to_s
              end

            else
              val  
            end # unless

          end # each

          @#{field}

        end

      }, __FILE__, __LINE__

    end # has_many  

  end # Generator  

end # ActsAsFiles