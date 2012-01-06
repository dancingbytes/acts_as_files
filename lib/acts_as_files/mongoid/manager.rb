# encoding: utf-8
module ActsAsFiles

  class Manager < ActsAsFiles::BaseManager

    class << self

      def append_file(obj, file_id, field)

        # Пытаемся преобразовать file_id в удобный нам вид
        file_id = if BSON::ObjectId.legal?(file_id) 
          BSON::ObjectId(file_id)
        elsif file_id.respond_to?(:id)
          file_id.id
        else
          file_id
        end

        # 0
        return if file_id.blank?

        # 1 Если file_id -- строка (путь к файлу)
        return ::Multimedia.new do |o|
                 
          o.context_type  = obj.class.name
          o.context_id    = obj.id
          o.context_field = field.to_s
          o.file_upload   = file_id

        end unless file_id.is_a?(BSON::ObjectId)

        # 2 Если file_id -- объект BSON::ObjectId
        if (el = ::Multimedia.where({ ActsAsFiles::ID => file_id }).first).nil?
          # Ничего не нашли в базе -- завершаем работу
          return nil
        end

        # 3 Объект найден в базе, но у него не задан контекст
        unless el.contexted?
            
          el.context_type   = obj.class.name
          el.context_id     = obj.id
          el.context_field  = field.to_s
          el.file_upload    = el.path(:source)

          return el

        end # unless

        # 4
        #
        # Если у файл задан контекст указанного объекта, либо
        # конекст удовлетворяет заданному объекту, но поле контекста
        # не соответствует указанному полю то создаем копию файла, указав
        # требуемые данные.
        #
        return ::Multimedia.new do |o|
                 
          o.context_type  = obj.class.name
          o.context_id    = obj.id
          o.context_field = field.to_s
          o.file_upload   = el.path(:source)

        end if !el.context_by?(obj) || !el.field_by?(field)

        # Во всех остальных случаях возвращаем nil
        nil
          
      end # append_file

    end # class << self

  end # Manager  

end # ActsAsFiles