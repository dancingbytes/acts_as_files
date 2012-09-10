# encoding: utf-8
require 'acts_as_files/version'
require 'acts_as_files/builder'
require 'girl_friday'
require 'filemagic'

module ActsAsFiles

  MONGOID = defined?(Mongoid)
  AR      = defined?(ActiveRecord)
  ID      = (ActsAsFiles::MONGOID ? :_id : :id)

  MIME    = ::FileMagic.mime

  if RUBY_PLATFORM.downcase.include?("darwin")
    CORES   = `sysctl hw.ncpu | awk '{print $2}'`.chop.to_i
  else
    CORES   = `cat /proc/cpuinfo | grep processor | wc -l`.chop.to_i
  end

  CRAWLER = ::GirlFriday::Queue.new('image_crawler', :size => ::ActsAsFiles::CORES) do |arr|

    (parent, mark, action) = arr

    el = parent.class.new

    el.name          = parent.name
    el.source_id     = parent.id
    el.context_type  = parent.context_type
    el.context_id    = parent.context_id
    el.context_field = parent.context_field
    el.position      = parent.position
    el.mime_type     = parent.mime_type
    el.name          = parent.name
    el.ext           = parent.ext
    el.file_upload   = parent.path(:source)

    unless action.nil?

      if action.is_a?(::Proc)
        el.custom_sizing(mark, &action)
      else
        el.custom_sizing(mark) do |file|
          file.resize(action.to_s)
        end

      end # if

    end # unless  

    el.save(validate: false)

  end # CRAWLER

  class << self

    def config
      
      unless @config
      
        r = ::ActsAsFiles::Builder::General.new
        @config = (r.compile || {})[::Rails.env || ::RAILS_ENV] || {}

      end # unless
      @config
      
    end # config

    def class_exists?(class_name)
      
      return false if class_name.blank?

      begin
        ::Object.const_defined?(class_name) ? ::Object.const_get(class_name) : ::Object.const_missing(class_name)
      rescue => e
        return false if e.instance_of?(NameError)
        raise e
      end

    end # class_exists?

    def nil_or_zero?(num)
      num.nil? || (num.is_a?(::Numeric) && num.zero?)
    end # nil_or_zero? 

  end # class << self

end # ActsAsFiles

require 'uri'

require 'acts_as_files/image_processor'
require 'acts_as_files/content_parser'
require 'acts_as_files/context_store'
require 'acts_as_files/base_manager'

require 'acts_as_files/multimedia/instance_methods'

require 'acts_as_files/railtie'
