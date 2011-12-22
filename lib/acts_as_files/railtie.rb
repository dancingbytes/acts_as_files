# encoding: utf-8
module ActsAsFiles

  class Railtie < ::Rails::Railtie #:nodoc:
    
    initializer 'acts_as_files' do |app|
    
      Mongoid::Document::ClassMethods.send(:include, ActsAsFiles::Base)
      if defined?(Kaminari)
        require 'kaminari/models/mongoid_extension'
        ActsAsFiles::Multimedia.send :include, Kaminari::MongoidExtension::Document
      end

    end

  end

end
