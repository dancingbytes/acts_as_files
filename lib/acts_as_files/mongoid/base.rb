# encoding: utf-8
require 'acts_as_files/mongoid/multimedia'
require 'acts_as_files/mongoid/generator'

module ActsAsFiles
  
  module Base
    
    def acts_as_files(&block)
      
#      extend  ActsAsTagging::Document::ClassMethods
      
      r = ActsAsFiles::Builder::Context.new
      r.instance_eval &block if block_given?
      
      ActsAsFiles::Generator.new(self, r.compile)

#      g.set_callback(:save, :after) do |document|
##        ActsAsFiles::AssociationManager.manage_fields(self)
#      end

    end # act_as_files
    
  end # Base
  
end # ActsAsFiles

Mongoid::Document::ClassMethods.send(:include, ActsAsFiles::Base)