# encoding: utf-8
module ActsAsFiles
  
  module Base
    
    def acts_as_files &block
      
#      extend  ActsAsTagging::Document::ClassMethods
      
#      ActsAsFiles::ContextManager[self.name] = ActsAsFiles::Builder.new(self, assoc_name.to_sym).generate(&block)
            
#      self.set_callback(:save, :after) do |document|
#        ActsAsFiles::AssociationManager.manage_fields(self)
#      end

    end # act_as_files
    
  end # Base
  
end # ActsAsFiles

ActiveRecord::Base.send(:include, ActsAsFiles::Base)