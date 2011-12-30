# encoding: utf-8
module ActsAsFiles

  module Multimedia
    
    extend ActiveSupport::Concern
    include Mongoid::Document

    # metas
    included do

      scope   :source,  ->(ids) {
        ids = [ids] unless ids.is_a? Array
        any_of({:source_id.in => ids}, {:_id.in => ids})
      }
      
      scope :copies_of, ->(id) {
        where(:source_id => id)
      }

      scope   :sources,  where(:source_id => nil)

    end # included  

    # methods

  end # Multimedia
  
end # ActsAsFiles


begin
  Multimedia.send(:include, ActsAsFiles::Multimedia)
rescue NameError

  class Multimedia
    include ActsAsFiles::Multimedia
  end

end # begin