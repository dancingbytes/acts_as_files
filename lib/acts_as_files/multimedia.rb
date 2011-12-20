# encoding: utf-8
module ActsAsFiles

  class Multimedia
    include Mongoid::Document

    extend  ActsAsFiles::FileUpload::ClassMethods
    include ActsAsFiles::FileUpload::InstanceMethods
    include ActsAsFiles::Order::InstanceMethods
    
    field :source_id
    field :ext
    field :mark
    field :width, :type => Integer
    field :height, :type => Integer
    field :context_type
    field :context_id
    field :context_field
    field :mime_type
    field :created_at, :type => DateTime
    field :position, :type => Integer
    field :size, :type => Integer
    field :name

    #set_table_name  "multimedias"
    
    belongs_to  :context, :polymorphic => true

    acts_as_tagging :if => ->(c) { c.source? }

    # Защищенные параметры
    attr_protected  :source_id, :ext, :size, :width, :height, :mark, :mime_type,
                    :context_type, :context_id, :context_field, :position

    validate        :valid_file_size

    before_create   :add_to_list_bottom, :add_system_tags
    before_save     :save_states
    before_save     ->() { self.created_at = DateTime.now unless self.created_at }
    
    after_create    :create_file
    after_update    :update_file

    after_save      :manage_image_copies
    after_save      :manage_context_state
    before_destroy  :delete_file, :eliminate_current_position
    after_destroy   :manage_context_state

    scope   :source,  ->(ids) {
      ids = [ids] unless ids.is_a? Array
      any_of({:source_id.in => ids}, {:_id.in => ids})
    }
    
    scope :copies_of, ->(id) {
      where(:source_id => id)
    }

    scope   :sources,  where(:source_id => nil)

    scope   :skip_ids, ->(ids) {
      ids = [ids] unless ids.is_a? Array
      not_in(:_id => ids) unless ids.blank?
    }

    scope   :skip_source, ->(source_id) {
      not_in(:_id => [source_id]) unless source_id.nil?
    }

    scope   :by_field,  ->(field_name) {
      where(:context_field => field_name.to_s)
    }

    scope   :general,  by_field('')

    scope   :dimentions, ->(*args) {
      if args.length > 0
      
        if (args[0].is_a?(String) || args[0].is_a?(Symbol))
          where(:mark => args[0].to_s)
        else
          hash = {}
          hash[:width]  = args[0] unless args[0].nil?
          hash[:height] = args[1] unless args[1].nil?
          where(hash)
        end
      
      else
        where(:mark => nil)
      end

    } # dimentions
    
    scope :filter_by_images,  where(:mime_type.in => [
        'image/jpeg',
        'image/pjpeg',
        'image/jpeg',
        'image/x-jps',
        'image/png',
        'image/gif',
        'image/tiff',
        'image/x-tiff',
        'image/x-windows-bmp',
        'image/bmp',
        'image/vnd.wap.wbmp'
      ] 
    ) # filter_by_images

    scope :filter_by_pdf,  where(:mime_type.in => [
        'application/pdf'
      ] 
    ) # filter_by_pdf

    scope :filter_by_doc,     where(:mime_type.in => [
        'application/msword', 
        'application/rtf',
        'application/x-rtf',
        'text/richtext',
        'application/vnd.oasis.opendocument.text'
      ] 
    ) # filter_by_doc

    scope :filter_by_archives,  where(:mime_type.in => [
        'application/x-gtar', 
        'application/x-compressed',
        'application/x-gzip',
        'multipart/x-gzip',
        'application/x-bzip',
        'application/x-bzip2',
        'application/x-7z-compressed',
        'application/x-rar-compressed',
        'application/arj'
      ] 
    ) # filter_by_archives

    def crop(*args)

      if (l = args.length) == 1 && (hs = args[0]).is_a?(Hash)
        x  = hs[:x] || hs['x']
        y  = hs[:y] || hs['y']
        w  = hs[:width] || hs['width']
        h  = hs[:height] || hs['height']
      elsif l > 1
        x, y, w, h = *args[0..4]
      else
        return false
      end

      image = custom_sizing { |fl| fl.crop(w,h,x,y) }
      return false unless image
      image.source_id = self.id
      image.save ? image : false

    end # crop

    def to_hash

      {
        "id"   => self.id,
        "name" => self.name,
        "ext"  => self.ext,
        "width"  => self.width,
        "height" => self.height,
        "thumb"  => self.thumb,
        "url"    => self.url,
        "size"   => self.size,
        "created_at" => self.created_at
      }

    end # to_hash
    
    def manage_context_state
      if self.context_id && self.respond_to?(:has_image)
        
        context_multimedias = self.class.where(:context_id => self.context_id)
        illustrated = context_multimedias.count > 0 ? true : false
        
        self.context.has_image = illustrated
        self.context.save
        
      end # if
    end # manage_context_state

    private
    
    def add_system_tags
      self.tag_sys_list << self.ext unless self.ext.empty?
    end # add_system_tags

    def valid_file_size
      return unless self.file_required?

      if self.file_upload.nil? || self.size == 0
      #if self.size == 0
        self.errors.add(:file_upload, "Выберите файл для загрузки.")
        return false
      end

      if self.size > config[:file_size_limit]
        self.errors.add(:file_upload,
          "Размер файла превышен! Допустимый размер: " <<
          "#{config[:max_size]} b. текущий размер файла: #{self.size} b.")
        return false
      end

    end # valid_file_size

  end # Multimedia

end # ActsAsFile