# encoding: utf-8
module ActsAsFiles

  class << self

    include Singleton

    def initialize
      @hash = {}
    end # initialize

    def self.[](context)
      instance[context]
    end # self.[]
      
    def self.[]=(context, params = {})
      instance[context] = params
    end # self.[]=

    def [](context)
      @hash[context] || {}
    end # []

    def []=(context, params = {})
      @hash[context] = params
    end # []=

  end # class << self

end # ActsAsFiles

require 'acts_as_files/image_processor'
require 'acts_as_files/content_parser'

require 'acts_as_files/builder'
require 'acts_as_files/railtie'

#require 'acts_as_files/configuration'
#require 'acts_as_files/order'
#require 'acts_as_files/image_processor'

#require 'acts_as_files/context_manager'
#require 'acts_as_files/file_upload'
#require 'acts_as_files/multimedia'
#require 'acts_as_files/association_manager'
#require 'acts_as_files/base'

#require 'acts_as_files/railtie'