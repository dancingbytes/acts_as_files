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

              if (file_id = ::Multimedia.url_to_id(url))

                el = ActsAsFiles::Manager.append_file(obj, file_id, field)

                if ActsAsFiles::BaseManager.success?(el, obj)
                  found = true
                  ids_save.push(el.id)
                end

              end # if

              el || false
              
            end # do

            # Прекращаем дальнейший парсинг, если задана только одна итерация и объект найден
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

      def success?(el, obj)

        puts "success? -> #{el.inspect}"

        return false if el.nil? || obj.nil?
        return true  if el.frozen?
        el.context_id = obj.id if el.context_id.nil?
        el.save

      end # success?

      private

      def equal_context?(obj, el, field)

        return false if el.nil?

        if el.context_by?(obj) && el.field_by?(field)
          el.freeze
          return true
        end
        false

      end # equal_context?

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
            
            return @#{field} if @#{field}
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

          el = obj.instance_variable_get("@#{field}".to_sym)
          if obj.try("#{field}_changed?")

            if ActsAsFiles::BaseManager.success?(el, obj)

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

      unless parse_from.nil?

        @context.class_eval %Q{

          def #{field.to_sym}(*args)
            ::Multimedia.by_context(self).by_field("#{field}").dimentions(*args).asc(:position)
          end

        }, __FILE__, __LINE__

      else

        @context.class_eval %Q{

          def #{field.to_sym}(*args)

            return @#{field} if @#{field}
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
      
      end # if  

      @context.set_callback(:save, :after) do |obj|

        unless parse_from.nil?          
          ActsAsFiles::Manager::parse_files_from(obj, field, parse_from.to_sym )
        else

          if obj.try("#{field}_changed?")

            ids_saved = []

            # Данные пришедшие в перенной @{field}
            (obj.instance_variable_get("@#{field}".to_sym) || []).each do |el|
              
              if ActsAsFiles::BaseManager.success?(el, obj)
                ids_saved.push(el.id) 
              end
                
            end # each

            # Удаляем все базовые файлы, кроме "сохраненных"
            ::Multimedia.
              by_context(obj).
              by_field(field).
              skip_ids(ids_saved).
              sources.
              destroy_all

            # Обвновляем порядок файлов
            ActsAsFiles::Manager::update_files_order(ids_saved) unless ids_saved.empty?

            obj.instance_variable_set("@#{field}".to_sym, nil)
            
          end # if

        end # unless  

      end # set_callback

    end # has_many

    def additional_methods_for(field)

      @context.class_eval %Q{

        def #{field}_changed?
          !@#{field}.nil?
        end
        
      }, __FILE__, __LINE__

    end # additional_methods_for 

  end # BaseManager

end # ActsAsFiles 