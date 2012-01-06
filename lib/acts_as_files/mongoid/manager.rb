# encoding: utf-8
module ActsAsFiles

  class Manager < ActsAsFiles::BaseManager

    class << self

      #
      # file_id может быть:
      #
      # -- BSON::ObjectId or BSON::ObjectId.legal?
      # -- Multimedia
      # -- String
      # -- File (like)
      # -- Other

      def append_file(obj, file_id, field)

        return if file_id.blank?

        # Пытаемся преобразовать file_id в BSON::ObjectId
        file_id = if BSON::ObjectId.legal?(file_id) 
          BSON::ObjectId(file_id)
        else
          file_id
        end

        # BSON::ObjectId or BSON::ObjectId.legal?
        if file_id.is_a?(BSON::ObjectId)
          el = ::Multimedia.where(ActsAsFiles::ID => file_id).first
        end # if

        # Multimedia
        if file_id.is_a?(Multimedia)
          
          el = if file_id.new_record?
            file_id
          else
            ::Multimedia.where(ActsAsFiles::ID => file_id.id).first
          end
            
        end # if  

        ::Multimedia.new do |o|
                 
          o.context_type  = obj.class.name
          o.context_id    = obj.id
          o.context_field = field.to_s

          if el
            o.file_upload = el.path(:source)
            o.name        = el.name 
          else
            o.file_upload = file_id
          end  

        end # if el.nil?

      end # append_file

    end # class << self

  end # Manager  

end # ActsAsFiles