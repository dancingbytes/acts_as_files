# encoding: utf-8
module ActsAsFiles
  
  module Base
    
    def acts_as_files(assoc_name = "files", &block)
      
      extend  ActsAsTagging::Document::ClassMethods
      
      ActsAsFiles::ContextManager[self.name] = ActsAsFiles::Builder.new(self, assoc_name.to_sym).generate(&block)
            
      self.set_callback(:save, :after) do |document|
        ActsAsFiles::AssociationManager.manage_fields(self)
      end
      
      has_many assoc_name.to_sym,
        :class_name => 'ActsAsFiles::Multimedia',
        :dependent  => :destroy,
        :as         => :context
      
    end # act_as_files
    
  end # Base
  
end # ActsAsFiles
