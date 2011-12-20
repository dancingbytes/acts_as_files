# encoding: utf-8
require 'uri'

module ActsAsFiles

  module FileUpload

    module ClassMethods
      
      def url_to_id(url)

        url_path = config[:url_path]
        #shuffle_id = URI.parse( url.sub(/#{url_path}/,'') ).path.sub(/\.\w+/,'').split('/').join
        shuffle_id = URI.parse( url.sub(/#{url_path}/,'') ).path.sub(/\.\w+/,'').gsub('/','').scan(/\w\w/)
        #arr = shuffle_id.scan(/\w\w/)
        time = shuffle_id[7..10]
        machine = shuffle_id[0..2]
        pid = shuffle_id[3..4]
        inc = shuffle_id[5..6] << shuffle_id[11]
        id = (time + machine + pid + inc).join
      end # url_to_id

      def get_from_url(url)

        id = url_to_id(url)
        where(:_id => id).first
        
      end # get_from_url
      
      def split_id(id)
        arr = id.to_s.scan(/\w\w/)
        time = arr[0..3] # 0
        machine = arr[4..6] # 1
        pid = arr[7..8] # 2
        inc = arr[9..11] # 3
        [time, machine, pid, inc]
      end # split_id
      
      def whole(id)
        arr = split_id(id)
        w = [arr[1..2].join] + arr[3][0..1]
      end # whole

      def rest(id)
        arr = split_id(id)
        arr[0].join + arr[3][2]
      end # rest

      def config
        ActsAsFiles::Configuration.instance.config
      end # config

      def destroy_each(ids, split_by = ",")

        ids = ids.split(split_by) if ids.is_a?(String)
        ids = [ids] unless ids.is_a?(Array)

        ids.each do |id|
          where(:_id => id).first.try(:destroy)
        end # each

      end # destroy_each

      private

      def clear_string(str)
        str.gsub("/", "")
      end # clear_string

      def clear_array(arr)
        arr.split("/").drop(1)
      end # clear_array

    end # ClassMethods

    module InstanceMethods

      # Задан ли контекст
      def contexted?
        !(self.context_type.blank? && self.context_id.nil?)
      end # contexted?

      # Задан ли контекст от указанного этого объекта
      def context_by?(obj)
        self.context_type.eql?(obj.class.name) && self.context_id == obj.id
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

        (result, answer) = [`file --mime-type -b "#{self.file_upload.path}"`.strip, $?]
        answer.exitstatus == 0 ? result : nil

      end # file_mime_type

      def config
        self.class.config
      end # config

      def file_upload

        if new_record?
          f = self.instance_variable_get(:@file_upload)
          return f if f.is_a?(Tempfile) || f.is_a?(File) || f.is_a?(ActionDispatch::Http::UploadedFile)
        else          
          f = self.instance_variable_get(:@file_upload) || self.path
        end
        f && File.file?(f) ? File.new(f) : nil

      end # file_upload

      def file_upload=(f)

        self.instance_variable_set(:@file_upload, f)
        initialize_file

      end # file_upload

      def source?
        self.source_id.nil?
      end # source?

      # Source identificator. Идентификатор источника.
      def sid
        self.source_id.nil? ? self.id : self.source_id
      end # sid

      # Директория, в которой распологается файл. Директории делятся на
      # 3 типа: исходники (private), общие файлы (public), thumbnail (public).
      # По-умолчанию выводится директория с общими файлами.
      def dir(looking_for = nil)

        dr = case(looking_for)
          when :thumb   then File.join(config[:local_thumb_path], whole(self.sid))
          when :source  then File.join(config[:local_source_path], whole(self.sid))
          else File.join(config[:local_path], whole(self.id))
        end

        # Создаем все необходимые директории, если таковые не существуют
        FileUtils.mkdir_p(dr, :mode => 0755) unless FileTest.directory?(dr)
        dr

      end # dir

      # Название файла в системе. Название файла может отличатся, в зависимости
      # от типа запрашиваемого объекта: исходник, общий файл, thumbnail.
      # По-умолчанию выводится название общего файла.
      def basename(looking_for = nil)

        return @basename if new_record? #(@file ? File.basename(@file) : nil) if new_record?

        case(looking_for)
          when :thumb   then "#{rest(self.sid)}.png"
          when :source  then "#{rest(self.sid)}.#{self.ext}"
          else "#{rest(self.id)}.#{self.ext}"
        end

      end # basename

      def path(looking_for = nil)

        return (@file ? @file.path : nil) if new_record?
        File.join(self.dir(looking_for), self.basename(looking_for))

      end # path

      def url(looking_for = nil)
        
        return if new_record?
        return if !self.image? && looking_for == :thumb

        (
          if looking_for == :thumb
            [config[:thumb_url_path], whole(self.sid), self.basename(:thumb)]
          else
            [config[:url_path], whole(self.id), self.basename]
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

      def resize(size_mark, size_str)

        return false unless self.image?
        
        image = custom_sizing { |file| file.resize(size_str) }
        image.mark = size_mark
        image.save ? image : false

      end # resize
      
      def opts
        ActsAsFiles::ContextManager[self.context_type]
      end # opts
      
      def save(options = {})
        
        if self.source? && self.contexted?
          (opts[:callbacks][:before_save] || []).each do |callback|
            callback.call self.context
          end # each
          
          if self.context_field && opts[:fields][self.context_field.to_sym][:callbacks]
            (opts[:fields][self.context_field.to_sym][:callbacks][:before_save] || []).each do |callback|
              callback.call self.context
            end # each
            
          end # if
          
          result = super(options)
          
          (opts[:callbacks][:after_save] || []).each do |callback|
            callback.call self.context
          end # each
          
          if self.context_field && opts[:fields][self.context_field.to_sym][:callbacks]
            
            (opts[:fields][self.context_field.to_sym][:callbacks][:after_save] || []).each do |callback|
              callback.call self.context
            end # each
            
          end # if
          
        else
          result = super options
        end # if
        result
      end # save
      
      def destroy(options = {})
        if self.source? && self.contexted?
          
          (opts[:callbacks][:before_destroy] || []).each do |callback|
            callback.call self.context
          end # each
          
          if self.context_field && opts[:fields][self.context_field.to_sym][:callbacks]
            (opts[:fields][self.context_field.to_sym][:callbacks][:before_destroy] || []).each do |callback|
              callback.call self.context
            end # each
            
          end # if
          
          result = super(options)
          
          (opts[:callbacks][:after_destroy] || []).each do |callback|
            callback.call self.context
          end # each
          
          if self.context_field && opts[:fields][self.context_field.to_sym][:callbacks]
            
            (opts[:fields][self.context_field.to_sym][:callbacks][:after_destroy] || []).each do |callback|
              callback.call self.context
            end # each
            
          end # if
          
        else
          result = super options
        end
        result
      end # destroy

      private
      
      # Ранее (смотреть комментарий к переопределению метода with_transaction_returning_status)
      # мы решили самосточятельно следить за целосьностью данных. Поэтому будем
      # отлавливать ошибки ActiveRecord::RecordInvalid и ActiveRecord::RecordNotUnique.
      # Да, отлов исключения не самая дешевая операция, но при можественных
      # инстансах приложения (и оптимистичном прогнозе -- вероятность пордачи
      # неверных данных на вход мала) это один из надежных способов (проверка
      # уникальности данных и/или их корректности мы отдаем на откуп СУБД).
      
=begin
      def create_or_update(*args)

        begin

          if self.source? && self.contexted?

            run_callbacks("handler_#{self.context_type}_before".to_sym)
            result = super
            run_callbacks("handler_#{self.context_type}_after".to_sym)
            
          else
            result = super            
          end
          result

        rescue ::ActiveRecord::RecordInvalid,
               ::ActiveRecord::RecordNotUnique
#               ::ActiveRecord::RecordNotSaved
          false
        end

      end # create_or_update
=end      
      def image
        self.image? ? ActsAsFiles::ImageProcessor.new(self.file_upload.path) : false
      end # image

      def create_file

        return if @file.nil?

        fp, ip = @file.path, self.path
        threads = []
        
        # Если файл является базовым то:
        if self.source_id.nil?

          # Обновляем ссылку на источник (то есть на самого себя)
          #self.source_id = self.id
          
          #self.class.where(:_id => self.id).update_all(
          #  :source_id  => self.source_id
          #)
          
          threads << Thread.new(fp, ip) do |fp, ip|
            
            # Сохраняем изображение (копируем).
            FileUtils.cp(fp, ip)
            # Выставляем права на файл
            FileUtils.chmod(0644, ip)
            
          end # Thread.new

          # Если картинка
          if @image

            # Сохраняем исходник.
            sp = self.path(:source)
            threads << Thread.new(fp, sp) do |fp, sp|
              
              FileUtils.cp(fp, sp)
              FileUtils.chmod(0644, sp)
              
            end # Thread.new
            
            threads << Thread.new(self) do |obj|
              # Создаем thumbnail.
              @image.thumb(80).save(self.path(:thumb))
            end # Thread.new

          end # if

        else
          
          threads << Thread.new(fp, ip) do |fp, ip|
            
            # Сохраняем изображение (перемещаем)
            FileUtils.mv(fp, ip)# unless fp == ip
            # Выставляем права на файл
            FileUtils.chmod(0644, ip)
            
          end # Thread.new

        end # if
        
        threads.each { |aThread|  aThread.join }

      end # create_file

      def update_file

        return if @file.nil?

        @context_state_changed = true
        fp, ip = @file.path, self.path

        path_name = "#{rest(self.id)}.*"

        unless fp == ip

          # Удаляем общий файл
          FileUtils.rm Dir.glob( File.join( self.dir, path_name ) ), :force => true

          # Сохраняем изображение (копируем).
          FileUtils.cp(fp, ip)

          # Выставляем права на файл
          FileUtils.chmod(0644, ip)

        end # unless

        if self.source?
          
          # Если картинка
          if @image

            # Удаляем исходник
            FileUtils.rm Dir.glob( File.join( self.dir(:source), path_name ) ), :force => true

            # Удаляем thumbnail
            FileUtils.rm Dir.glob( File.join( self.dir(:thumb),  path_name ) ), :force => true
          
            # Сохраняем исходник.
            sp = self.path(:source)
            FileUtils.cp(fp, sp)
            FileUtils.chmod(0644, sp)

            # Создаем thumbnail.
            @image.thumb(80).save(self.path(:thumb))

          end # if

        end # if

      end # update_file

      def initialize_file

        @file = self.file_upload
        return if @file.nil?

        # Опреледяем расширение файла
        self.ext = if @file.respond_to?(:original_filename)
          File.extname(@file.original_filename)
        else
          File.extname(@file.path)
        end
        self.ext.force_encoding(Encoding::UTF_8) if self.ext.respond_to?(:force_encoding)

        @basename = if @file.respond_to?(:original_filename)
          File.basename(@file.original_filename, self.ext)
        else
          File.basename(@file.path, self.ext)
        end
        @basename.force_encoding(Encoding::UTF_8) if @basename.respond_to?(:force_encoding)
        
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

        # Является ли файл изображением?
        if (@image = image)

          image_size_correction

          self.width  = @image.width
          self.height = @image.height
          self.ext    = @image.format

        end # if
        
        # Определяем размеры файла
        self.size = @file.respond_to?(:size) ? @file.size : @file.stat.size

      end # initialize_file

      def image_size_correction

        return if self.opts.empty?

        max_size = self.opts[:max_size]
        unless (field_options = self.opts[:fields][self.context_field]).nil?
          max_size = field_options[:max_size] || max_size
        end

        unless max_size.blank?

          @image.resize(max_size)
          @image.save
          @image = ActsAsFiles::ImageProcessor.new(self.file_upload.path)

        end # unless

      end # image_size_correction

      def ident
        self.class.ident(self)
      end # ident

      def whole(numb = ident)
        self.class.whole(numb)
      end # whole

      def rest(numb = ident)
        self.class.rest(numb)
      end # rest

      def split_id(numb = ident)
        self.class.split_id(numb)
      end # split_id

      def delete_file

        path_name = "#{rest(self.id)}.*"

        # Удаляем общий файл
        FileUtils.rm Dir.glob( File.join( self.dir, path_name ) ), :force => true        
        # Удаляем thumbnail
        FileUtils.rm Dir.glob( File.join( self.dir(:thumb),  path_name ) ), :force => true
        # Удаляем исходник
        FileUtils.rm Dir.glob( File.join( self.dir(:source), path_name ) ), :force => true

        # Если удаляем исходный файл, то удалим все связанные с ним копии
        self.class.copies_of(self.id).destroy_all if self.source?
        true

      end # delete_file

      # Создании копии изображения (с возможностью преобразования).
      # Информация о контексте изображения наследуется от родительского.
      def custom_sizing

        return unless self.image?
        
        fp = self.path
        if block_given?
          tf = ActsAsFiles::ImageProcessor.new(fp)
          tf = yield(tf)
          tf.save(File.join(Dir::tmpdir, "#{self.id}-#{Time.now.to_f}-#{rand(10)}-#{self.ext}.tmp"))
          fp = tf.path
        end
        
        self.class.new({ :file_upload => fp }) do |image|
          image.name          = self.name
          #image.sourced       = false
          image.source_id     = self.id
          image.context_type  = self.context_type
          image.context_id    = self.context_id
          image.context_field = self.context_field
        end
        
      end # custom_sizing

      def save_states
        
        @context_state_changed = new_record? || 
          self.context_type_changed?  ||
          self.context_id_changed?    ||
          self.context_field_changed?
        nil

      end # save_states

      # Для основного изображения создаем нужные копии, удаляем старые
      def manage_image_copies
        return if self.opts.empty?
        return unless @context_state_changed
        return unless self.image?
        return unless self.source?
        
        # Удаляем всех потомков
        self.class.copies_of(self.id).destroy_all
        
        threads = []
        
        unless self.context_field.blank?

          unless (field = self.opts[:fields][self.context_field.to_sym]).nil?

            (field[:copies] || {}).each do |mark, size|
              #self.resize(mark, size)
              
              threads << Thread.new(self, mark, size) do |obj, mark, size|
                obj.resize(mark, size)
              end # Thread.new
              
            end # each

          end # unless

        else

          (self.opts[:copies] || {}).each do |mark, size|
            #self.resize(mark, size)
            
            threads << Thread.new(self, mark, size) do |obj, mark, size|
              obj.resize(mark, size)
            end # Thread.new
            
          end

        end # unless
        
        threads.each { |aThread|  aThread.join }

      end # manage_image_copies

    end # InstanceMethods

  end # FileUpload

end # ActsAsFiles