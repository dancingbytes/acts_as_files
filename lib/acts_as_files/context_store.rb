# encoding: utf-8
require 'singleton'

module ActsAsTagging

  class ContextStore
    
    include Singleton

    def initialize
      @hash = {}
    end # initialize

    def self.[](context)
      instance[context]
    end # self.[]
    
    def self.[]=(context, datas = {})
      instance[context] = datas
    end # self.[]=

    def [](context)
      @hash[context] || {}
    end # []

    def []=(context, datas = {})      
      @hash[context] = datas
    end # []=

  end # ContextStore

end # ActsAsTagging