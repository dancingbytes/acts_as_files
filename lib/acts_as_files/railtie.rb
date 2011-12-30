# encoding: utf-8
module ActsAsFiles

  class Railtie < ::Rails::Railtie #:nodoc:
    
    initializer 'acts_as_files' do |app|
    
      if defined?(Mongoid)
        require 'acts_as_files/mongoid/base'
      elsif defined?(ActiveRecord)
        require 'acts_as_files/active_record/base'
      end  

    end # initializer

  end # Railtie

end # ActsAsFiles