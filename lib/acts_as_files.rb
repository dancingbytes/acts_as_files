# encoding: utf-8
require 'acts_as_files/builder'

module ActsAsFiles

  MONGOID = defined?(Mongoid)
  AR      = defined?(ActiveRecord)
  ID      = (ActsAsFiles::MONGOID ? :_id : :id)

  class << self

    def config
      
      unless @config
      
        r = ActsAsFiles::Builder::General.new
        @config = (r.compile || {})[Rails.env || RAILS_ENV] || {}

      end # unless
      @config
      
    end # config

    def class_exists?(class_name)
      
      return false if class_name.blank?

      begin
        Object.const_defined?(class_name) ? Object.const_get(class_name) : Object.const_missing(class_name)
      rescue => e
        return false if e.instance_of?(NameError)
        raise e
      end

    end # class_exists?

  end # class << self

end # ActsAsFiles

require 'acts_as_files/image_processor'
require 'acts_as_files/content_parser'
require 'acts_as_files/context_store'
require 'acts_as_files/base_manager'

require 'acts_as_files/multimedia/instance_methods'

require 'acts_as_files/railtie'