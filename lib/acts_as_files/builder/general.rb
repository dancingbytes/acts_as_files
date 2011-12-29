# encoding: utf-8
module ActsAsFiles

  def self.config
    
    unless @config
    
      r = ActsAsFiles::Builder::General.new
      @config = (r.compile || {})[Rails.env || RAILS_ENV || ENV] || {}

    end # unless
    @config
    
  end # config


  module Builder

    class General

      def initialize

        @params = {}

        # default params
        development

        # exec conf file
        config_file = File.join(Rails.root, "config", "acts_as_files.rb")
        self.instance_eval(File.read(config_file), config_file) if File.exists?(config_file)

      end # new  

      def compile
        @params
      end # compile

      private

      def method_missing(name, *args, &block)

        if [:development, :production, :test].include?(name)

          r = ActsAsFiles::Builder::GeneralParams.new
          r.instance_eval &block if block_given?
          @params[name.to_s] = r.compile

        end # if

      end # method_missing

    end # General


    class GeneralParams

      def initialize
        
        @params = {}

        # default params
        file_size_limit
        url_path
        thumb_url_path
        local_path
        local_thumb_path
        local_source_path

      end # new
      
      def compile
        @params
      end # compile

      private

      def method_missing(name, *args, &block)
      end # method_missing

      def file_size_limit(val = nil)
        @params["file_size_limit"] = val || 32*1024*1024
      end # file_size_limit
      
      def url_path(val = nil)
        @params["url_path"] = val || '/public'
      end # url_path
      
      def thumb_url_path(val = nil)
        @params["thumb_url_path"] = val || '/public/thumb'
      end # thumb_url_path

      def local_path(val = nil)
        @params["local_path"] = File.expand_path(val || 'public', Rails.root)
      end # local_path

      def local_thumb_path(val = nil)
        @params["local_thumb_path"] = File.expand_path(val || 'public/thumb', Rails.root)
      end # local_thumb_path

      def local_source_path(val = nil)
        @params["local_source_path"] = File.expand_path(val || 'src', Rails.root)
      end # local_source_path

    end # GeneralParams

  end # Builder

end # ActsAsFiles