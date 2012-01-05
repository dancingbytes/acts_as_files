# encoding: utf-8
module ActsAsFiles

  class Railtie < ::Rails::Railtie #:nodoc:
    
    initializer 'acts_as_files' do |app|
    
      if ActsAsFiles::MONGOID
        require 'acts_as_files/mongoid/base'
      elsif ActsAsFiles::AR
        require 'acts_as_files/active_record/base'
      end

    end # initializer

    config.to_prepare do

      if ActsAsFiles::MONGOID
        load 'acts_as_files/mongoid/setup.rb'
      elsif ActsAsFiles::AR
        load 'acts_as_files/active_record/setup.rb'
      end

    end # to_prepare

  end # Railtie

end # ActsAsFiles