# encoding: utf-8
module ActsAsFiles

  class AssociationManager
    
    class << self
      
      def manage_fields(obj)

        datas = ActsAsFiles::ContextManager[ obj.class.name ]

        (datas[:fields] || {}).each do |field, params|
          
          if params[:relation] == :has_one
            
            manage_has_one(obj, field)
            
          else # params[:relation] == :has_many
            
            # Выбираем данные по заданному полую/методу из базы данных
            ids_db  = obj.try(field).sources.distinct(:_id).map{|i| i.to_s}
            
            
            if params[:parse_from]
              
              manage_parse_from(obj, field, ids_db, params[:parse_from])
      
            else
              
              manage_has_many(obj, field, ids_db)
      
            end # if

          end # if

        end # each
        nil

      end # manage_fields
      
      def manage_has_one(obj, field)
        
        id_new = obj.instance_variable_get("@#{field}".to_sym)
        return unless id_new
        
        # Удаляем все базовые файлы, кроме текущего
        ActsAsFiles::Multimedia.where(:context_id => obj.id).skip_ids([id_new]).destroy_all
        # Создаем/присваеваем новый файл
        manage_file(obj, id_new, field)
        
      end # manage_has_one
      
      def manage_has_many(obj, field, ids_db)
        
        ids_new = obj.instance_variable_get("@#{field}".to_sym)
        ids_add = []
        
        if ids_new.present?
          
          ids_del = (ids_db - ids_new)
          
          # На удаление
          unless ids_del.empty?
            obj.try(field).source(ids_del).destroy_all
          end

          ids_add = (ids_new - ids_db)
          
          added_ids = {} # {el_id => real_id}
          # На добавление
          ids_add.each do |el_id|
            added_ids[el_id] = "#{manage_file(obj, el_id, field).try(:id)}"
          end
          
          added_ids.each {|k,v| ids_new[ids_new.index(k)] = v}
          manage_files_order(obj.try(field), ids_new)
          
        end # if
        
      end # manage_has_many
      
      def manage_parse_from(obj, field, ids_db, parse_from)
        
        return unless obj.try("#{parse_from}_changed?")
        
        value = obj.try(parse_from)
        
        {"img" => "src", "a" => "href"}.each do |tag, attribute|
        
          cp = ActsAsFiles::ContentParser.new(".//#{tag}", "#{attribute}")
          value = cp.parse(value) do |file_id|
            
            if !file_id.nil? && (result = manage_file(obj, file_id, field))
              result
            else
              ids_del = ids_db - [file_id]
              false
            end # if

          end # parse
          
        end # each
              
        obj.try(field).source(ids_del).destroy_all
        obj.class.where(:_id => obj.id).update_all(parse_from => value)
        
      end # manage_parse_from
      
      #################################################################################
      
      def manage_files_order(field, ids)
        
        field.sources.each do |m|
          
          m.position = ids.index(m.id.to_s)
          m.save
          
        end # each
        
      end # manage_files_order
      
      def manage_file(obj, file_id, field)
        # Ищем файл
        if (el = ActsAsFiles::Multimedia.where(:_id => file_id).first)
          unless el.contexted?
            el.context_type  =  obj.class.name
            el.context_id    =  obj.id
            el.context_field =  field
            el.file_upload   =  el.path
            return el if el.save
            
          else

            # Если у файл задан контекст указанного объекта, либо
            # конекст удовлетворяет заданному объекту, но поле контекста
            # не соответствует указанному полю то создаем копию файла, указав
            # требуемые данные.
            #
            # В противном случае ничего не делаем
            #
            if !el.context_by?(obj) || !el.field_by?(field)

              el_copy = ActsAsFiles::Multimedia.new do |o|
                o.context_type  =  obj.class.name
                o.context_id    =  obj.id
                o.context_field =  field
                o.file_upload   = el.path
              end
              return el_copy if el_copy.save

            end # if

          end # unless
          
          el
        else
          nil
        end # if
        
      end # manage_file
    
    end # class << self

  end # AssociationManager

end # ActsAsFiles