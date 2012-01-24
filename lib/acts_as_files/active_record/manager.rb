# encoding: utf-8
module ActsAsFiles

  class Manager < ActsAsFiles::BaseManager

    class << self

      #
      # file_id может быть:
      #
      # -- Fixnum (Integer)
      # -- Multimedia
      # -- Other

      def append_file(obj, file_id, field)
        
        return if file_id.nil?

        # Multimedia
        if file_id.is_a?(Multimedia)

          el = if file_id.new_record?
            file_id
          else
            ::Multimedia.where(ActsAsFiles::ID => file_id.id).first
          end

          # Если найденный объект полностью соотвествует контексту -- возвращаем объект
          return el if equal_context?(obj, el, field)

        else

          # Пытаемся преобразовать file_id в Fixnum
          if (int = file_id.to_s.to_i(10)) != 0

            # Ищем объект в базе
            el = ::Multimedia.where(ActsAsFiles::ID => int).first
          
            # Если найденный объект полностью соотвествует контексту -- возвращаем объект
            return el if equal_context?(obj, el, field)

          end # if

        end # if

        ::Multimedia.new do |o|
                 
          o.context_type  = obj.class.name
          o.context_id    = obj.id
          o.context_field = field.to_s
          
          if el
            o.file_upload = el.image? ? el.path(:source) : el.path
            o.name        = el.name 
          else
            o.file_upload = file_id
          end  

        end # new

      end # append_file

    end # class << self 

  end # Manager

end # ActsAsFiles