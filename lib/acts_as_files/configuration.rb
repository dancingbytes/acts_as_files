# encoding: utf-8
module ActsAsFiles

  class << self

    def system
      ActsAsFiles::Configuration.system
    end # system

    def [](context)
      ActsAsFiles::Configuration[context]
    end # []

    def []=(context, params = {})
      ActsAsFiles::Configuration[context] = params
    end # []=

  end # class << self

  class Configuration

    include Singleton

    class << self

      def [](context)
        instance[context]
      end # self.[]
        
      def []=(context, params = {})
        instance[context] = params
      end # self.[]=

      def system
        instance.system
      end # system

    end # class << self

    def initialize
      
      @hash = {}
      r = ActsAsFiles::Builder::General.new
      @system = (r.compile || {})[Rails.env || RAILS_ENV || ENV] || {}

    end # new

    def system
      @system
    end # system

    def [](context)
      @hash[context] || {}
    end # []

    def []=(context, params = {})
      @hash[context] = params
    end # []=

  end # Configuration
  
end # ActsAsFiles