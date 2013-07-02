# encoding: utf-8
module ActsAsFiles

  module MultimediaBase

    module InstanceMethods

      # Задан ли контекст
      def contexted?
        !(self.context_type.blank? || ::ActsAsFiles.nil_or_zero?(self.context_id))
      end # contexted?

      # Задан ли контекст от указанного этого объекта
      def context_by?(obj)

        return false if obj.nil? || obj.id.blank?
        self.context_type.eql?(obj.class.to_s) && self.context_id.eql?(obj.id)

      end # context_by?

      def field_by?(field)
        self.context_field.eql?(field)
      end # field_by?

      def image?
        self.mime_type && self.mime_type.split("/").first == "image"
      end # image?

      #
      # Определение mime-типа файла.
      # ВНИМАНИЕ! Корректная работа гарантирована только в Linux (Ubuntu).
      #
      def file_mime_type

        begin
          ::ActsAsFiles::MIME.file(self.path, true)
        rescue
          nil
        end  

      end # file_mime_type

      def file_upload

        f = (self.instance_variable_get(:@file_upload) || self.path(:source))
        return f if f.is_a?(Tempfile) || f.is_a?(File) || f.is_a?(::ActionDispatch::Http::UploadedFile)
        f && ::File.file?(f.to_s) ? ::File.new(f) : nil

      end # file_upload

      def file_upload=(f)

        self.instance_variable_set(:@file_upload, f)
        initialize_file

      end # file_upload

      def source?
        ::ActsAsFiles.nil_or_zero?(self.source_id)
      end # source?

      # Source identificator. Идентификатор источника.
      def sid
        self.source? ? self.id : self.source_id
      end # sid

      # Директория, в которой распологается файл. Директории делятся на
      # 3 типа: исходники (private), общие файлы (public), thumbnail (public).
      # По-умолчанию выводится директория с общими файлами.
      def dir(looking_for = nil)

        dr = case(looking_for)
          when :thumb   then ::File.join(::ActsAsFiles.config["local_thumb_path"], diff(self.sid))
          when :source  then ::File.join(::ActsAsFiles.config["local_source_path"], diff(self.sid))
          else ::File.join(::ActsAsFiles.config["local_path"], diff(self.id))
        end

        # Создаем все необходимые директории, если таковые не существуют
        ::FileUtils.mkdir_p(dr, :mode => 0755) unless ::FileTest.directory?(dr)
        dr

      end # dir

      # Название файла в системе. Название файла может отличатся, в зависимости
      # от типа запрашиваемого объекта: исходник, общий файл, thumbnail.
      # По-умолчанию выводится название общего файла.
      def basename(looking_for = nil)

        return @basename if new_record?

        case(looking_for)
          when :thumb   then "#{rest(self.sid)}.png"
          when :source  then "#{rest(self.sid)}.#{self.ext}"
          else "#{rest(self.id)}.#{self.ext}"
        end

      end # basename

      def path(looking_for = nil)

        return (@file ? @file.path : nil) if new_record?
        ::File.join(self.dir(looking_for), self.basename(looking_for))

      end # path

      def url(looking_for = nil)
        
        return if new_record?
        return if !self.image? && looking_for == :thumb

        (
          if looking_for == :thumb
            [::ActsAsFiles.config["thumb_url_path"], diff(self.sid), self.basename(:thumb)]
          else
            [::ActsAsFiles.config["url_path"], diff(self.id), self.basename]
          end
        ).flatten.join("/")

      end # url

      def thumb
        self.url(:thumb)
      end # thumb

      def file_changed?
        !self.instance_variable_get(:@file_upload).nil?
      end # file_changed?

      def file_required?
        new_record? || self.file_changed?
      end # file_required?

      # Преобразование изображения
      def custom_sizing(mark = nil)

        return self unless self.image?
        
        tf = ::ActsAsFiles::ImageProcessor.new(self.file_upload)
        tf = yield(tf) if block_given?
        
        if tf.save( ::File.join(::Dir::tmpdir, "#{self.id}-#{::Time.now.to_f}-#{self.ext}.tmp") )
          self.file_upload = tf.path
          self.mark = mark if mark
        end

        @temp_file = tf.path
        self
        
      end # custom_sizing

      def save(opts = {})

        return false if self.file_upload.nil? || !valid_size?

        nr = new_record?
        initialize_image
        self.updated_at = ::Time.now.utc

        begin

          if (result = super(opts))
            nr ? create_file : update_file
          end
          result  

        rescue => e
          
          self.errors.add(:file_upload, e.message)
          self.destroy
          false

        ensure            
          ::File.unlink(@temp_file) if @temp_file && ::File.exist?(@temp_file)
        end

      end # save

      def destroy

        if (result = super)
          delete_file
        end
        result  

      end # destroy

      def file_valid?
        !self.mime_type.blank? && valid_size?
      end # file_valid?

      private

      def valid_size?
        self.size && (1..::ActsAsFiles.config["file_size_limit"]).include?(self.size)
      end # valid_size?

      def whole(numb)
        self.class.whole(numb)
      end # whole

      def rest(numb)
        self.class.rest(numb)
      end # rest

      def diff(numb)
        self.class.diff(numb)
      end # diff  

      def initialize_file

        @file = self.file_upload
        return if @file.nil?

        if self.source?

          # Опреледяем расширение файла
          self.ext = if @file.respond_to?(:original_filename)
            ::File.extname(@file.original_filename)
          else
            ::File.extname(@file.path)
          end
          self.ext.force_encoding(::Encoding::UTF_8) if self.ext.respond_to?(:force_encoding)

          @basename = if @file.respond_to?(:original_filename)
            ::File.basename(@file.original_filename, self.ext)
          else
            ::File.basename(@file.path, self.ext)
          end
          @basename.force_encoding(::Encoding::UTF_8) if @basename.respond_to?(:force_encoding)
          
          # Устанавливаем название файла
          self.name = @basename if self.name.blank?

          # Mime type
          self.mime_type = self.file_mime_type

          unless self.ext.blank?
            # Убираем лишнюю точку вначале расширения
            self.ext.gsub!(/^\./, '')
          else
            self.ext = "unknown"
          end

        end # if
        
        # Определяем размеры файла
        self.size = @file.respond_to?(:size) ? @file.size : @file.stat.size

      end # initialize_file

      def configs

        return {} if self.context_type.blank?
        return {} unless ::ActsAsFiles.class_exists?(self.context_type)
        (::ActsAsFiles::ContextStore[self.context_type] || {})[self.context_field] || {}
        
      end # configs

      def initialize_image

        return if @file.nil? || !self.image?
        
        @source_image = @file

        do_action(self, configs[:default]) if self.source?

        @image = ::ActsAsFiles::ImageProcessor.new(self.file_upload)

        self.width  = @image.width
        self.height = @image.height
        self.ext    = @image.format

      end # initialize_image

      def create_file

        fp, ip = @file.path, self.path
        if fp != ip

          # Сохраняем файл (копируем).
          ::FileUtils.cp(fp, ip)
          # Выставляем права на файл
          ::FileUtils.chmod(0644, ip)

        end # if

        # Если файл не является базовым и не картинка -- завершаем работу.
        return if !self.source? || !@image

        fp, sp = @source_image.path, self.path(:source)
        if fp != sp

          # Сохраняем исходник.
          ::FileUtils.cp(fp, sp) 
          # Выставляем права на файл
          ::FileUtils.chmod(0644, sp)

        end # if  

        # Создаем thumbnail.
        @image.thumb(80).save(self.path(:thumb))

        # Создаем копии изображений
        (configs[:marks] || {}).each do |mark, value|
          ::ActsAsFiles.crawler [self, mark, value]
        end  

      end # create_file

      def update_file

        return if @file.nil?

        # Удаляем общий файл
        ::FileUtils.rm ::Dir.glob( ::File.join( self.dir, "#{rest(self.id)}.*" ) ), :force => true

        # Удалим все копии (если файл являектся базовым)
        self.class.copies_of(self.id).destroy_all if self.source?
        
        # Создадим заново (по новыми данным)
        create_file

      end # update_file

      def delete_file

        path_name = "#{rest(self.id)}.*"

        # Удаляем общий файл
        ::FileUtils.rm ::Dir.glob( ::File.join( self.dir, path_name ) ), :force => true

        return unless self.source?
          
        # Удаляем thumbnail
        ::FileUtils.rm ::Dir.glob( ::File.join( self.dir(:thumb),  path_name ) ), :force => true
          
        # Удаляем исходник
        ::FileUtils.rm ::Dir.glob( ::File.join( self.dir(:source), path_name ) ), :force => true

        # Если удаляем исходный файл, то удалим все связанные с ним копии
        self.class.copies_of(self.id).destroy_all

      end # delete_file

      def do_action(el, action = nil, mark = nil)

        return if action.nil?

        if action.is_a?(Proc)
          el.custom_sizing(mark, &action)
        else

          el.custom_sizing(mark) do |file|
            file.resize(action.to_s)
          end

        end # if

      end # do_action

    end # InstanceMethods

  end # MultimediaBase

end # ActsAsFiles
