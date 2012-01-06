# encoding: utf-8
module ActsAsFiles

  class BaseManager

    class << self

      #
      # Основные рабочие методы
      #
      def append_file(*args)
        raise "ActsAsFiles::BaseManager. Class method `append_file` must be rewrited!"
      end # append_file

      def parse_files_from(obj, field, parse_from, all = true)

        return unless obj.respond_to?(parse_from)
        return unless obj.try("#{parse_from}_changed?")

        # Экземпляры Multimedia на сохрарнение
        ids_save = []

        # Парсим контент по списку тегов
        unless (content = obj.try(parse_from)).blank?

          { 
            "img" => "src", 
            "a"   => "href"
          }.each do |tag, attribute|
            
            found = false

            content = ActsAsFiles::ContentParser.parse(".//#{tag}", "#{attribute}", content) do |url|

              result = false

              if (file_id = ::Multimedia.get_from_url(url))

                found = true
                el = append_file(obj, file_id, field)

                if el && el.save
                  ids_save << (result = el.id)
                end

              end # if

              result

            end # do

            # Прекращаем дальнеый парсинг, если задана только одна итерация и найден объект
            break if !all && found

          end # each  

          # Обновляем контент
          obj.class.where(ActsAsFiles::ID => obj.id).update_all(parse_from => content)

        end # unless

        # Удаляем все файлы, кроме тех что в массиве ids_save
        ::Multimedia.
          by_context(obj).
          by_field(field).
          skip_ids(ids_save).
          sources.
          destroy_all

      end # parse_files_from

      def update_files_order(ids)
        
        ids.each_index do |i|
          ::Multimedia.source(ids[i]).update_all(:position => i + 1)
        end # each_index
          
      end # update_files_order

    end # class << self


    def initialize(context, opts = {})
      
      @context, @opts = context, opts
      init

    end # new

    private

    def init

      cs = ActsAsFiles::ContextStore[@context.to_s] = {}

      (@opts[:one] || {}).each { |field, val|

        cs[field.to_s] = val
        has_one(field, val[:parse_from])
        additional_methods_for(field)
        
      }

      (@opts[:many] || {}).each { |field, val|
        
        cs[field.to_s] = val
        has_many(field, val[:parse_from])
        additional_methods_for(field)        

      }

    end # init

    #
    # Relations 
    #
    def has_one(field, parse_from = nil)

      if parse_from.nil?

        @context.class_eval %Q{

          def #{field.to_sym}(*args)
            
            return @#{field}.freeze if @#{field}
            ::Multimedia.by_context(self).by_field("#{field}").dimentions(*args).first

          end

          def #{field.to_sym}=(val)
            @#{field} = ActsAsFiles::Manager.append_file(self, val, "#{field}")
          end

        }, __FILE__, __LINE__

      else  

        @context.class_eval %Q{

          def #{field.to_sym}(*args)            
            ::Multimedia.by_context(self).by_field("#{field}").dimentions(*args).first
          end

        }, __FILE__, __LINE__

      end # if

      @context.set_callback(:save, :after) do |obj|

        unless parse_from.nil?
          ActsAsFiles::Manager::parse_files_from(obj, field, parse_from.to_sym, false)
        else

          el_id = obj.instance_variable_get("@#{field}".to_sym)
          if obj.try("#{field}_changed?")

            el = ActsAsFiles::Manager::append_file(obj, el_id, field)
            if el && el.save

              # Удаляем все базовые файлы, кроме текущего
              ::Multimedia.
                by_context(obj).
                by_field(field).
                skip_ids(el.id).
                sources.
                destroy_all

            end # if

            obj.instance_variable_set("@#{field}".to_sym, nil)

          end # if

        end # unless  

      end # set_callback

    end # has_one  

    def has_many(field, parse_from = nil)

      if parse_from.nil?

        @context.class_eval %Q{

          def #{field.to_sym}(*args)

            return @#{field}.map(:freeze) if @#{field}
            ::Multimedia.by_context(self).by_field("#{field}").dimentions(*args).asc(:position)

          end

          def #{field.to_sym}=(val)

            val = [val] unless val.is_a?(Array)

            @#{field} = []
            val.compact.uniq.each do |el|
              @#{field} << ActsAsFiles::Manager.append_file(self, el, "#{field}")
            end # each

            @#{field}

          end

        }, __FILE__, __LINE__
      
      else

        @context.class_eval %Q{

          def #{field.to_sym}(*args)            
            ::Multimedia.by_context(self).by_field("#{field}").dimentions(*args).asc(:position)
          end

        }, __FILE__, __LINE__

      end # if  

      @context.set_callback(:save, :after) do |obj|

        unless parse_from.nil?          
          ActsAsFiles::Manager::parse_files_from(obj, field, parse_from.to_sym )
        else

          if obj.try("#{field}_changed?")

            # Выбираем данные по заданному полую/методу из базы данных
            ids_db = ::Multimedia.
              by_context(obj).
              by_field(field).
              sources.
              distinct(ActsAsFiles::ID)

            # Данные пришедшие в перенной @{field}
            ids_new = (obj.instance_variable_get("@#{field}".to_sym) || []).map(&:id)
            
            # На удаление
            ids_del = []

            # На добавление
            (ids_new - ids_db).each do |el_id|

              el = ActsAsFiles::Manager::append_file(obj, el_id, field)
              if !el || !el.save
                ids_del.push(ids_new.delete(el_id))
              end  
              
            end # each

            ids_del += (ids_db - ids_new)
            ids_del.uniq!
            ids_del.compact!
            
            # Удаляем
            ::Multimedia.source(ids_del).destroy_all unless ids_del.empty?

            # Обвновляем порядок файлов
            ActsAsFiles::Manager::update_files_order(ids_new)

            obj.instance_variable_set("@#{field}".to_sym, nil)
            
          end # if

        end # unless  

      end # set_callback

    end # has_many

    def additional_methods_for(field)

      @context.class_eval %Q{

        def #{field}_changed?
          !@#{field}.blank?
        end
        
      }, __FILE__, __LINE__


    end # additional_methods_for 

  end # BaseManager

end # ActsAsFiles 