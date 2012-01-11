# encoding: utf-8
require 'acts_as_files/mongoid/multimedia/class_methods'
require 'acts_as_files/mongoid/multimedia/instance_methods'

module ActsAsFiles

  module Multimedia
    
    extend  ActiveSupport::Concern
    include Mongoid::Document
    
    extend  ActsAsFiles::Multimedia::ClassMethods
    include ActsAsFiles::Multimedia::InstanceMethods

    # metas
    included do

      field :source_id
      field :ext
      field :mark
      field :width,         :type => Integer
      field :height,        :type => Integer
      field :context_type
      field :context_id
      field :context_field
      field :mime_type
      field :updated_at,    :type => DateTime
      field :position,      :type => Integer
      field :size,          :type => Integer
      field :name

      index :mark,          :background => true   
      index :context_type,  :background => true
      index :context_id,    :background => true
      index :context_field, :background => true   
      index :position,      :background => true
      index :source_id,     :background => true


      # Защищенные параметры
      attr_protected  :source_id,
                      :ext,
                      :mark,
                      :width,
                      :height,
                      :context_type,
                      :context_id,
                      :context_field,
                      :mime_type,
                      :updated_at,
                      :position,
                      :size
                      

      scope   :source,  ->(ids) {
        ids = [ids] unless ids.is_a? Array
        any_of({:source_id.in => ids}, {:_id.in => ids})
      }
      
      scope :copies_of, ->(id) {
        where(:source_id => id) if id
      }

      scope   :sources,  where(:source_id => nil)

      scope   :skip_ids, ->(ids) {
        
        unless ids.blank?
          ids = [ids] unless ids.is_a? Array
          not_in(:_id => ids) 
        end
          
      }

      scope   :by_field,  ->(field_name) {
        where(:context_field => field_name.to_s) if field_name
      }

      scope   :by_context,  ->(obj) {
        where(:context_type => obj.class.name, :context_id => obj.id) if obj
      }

      scope   :general,  by_field('')

      scope   :dimentions, ->(*args) {

        if args.length > 0
        
          if (args[0].is_a?(String) || args[0].is_a?(Symbol))
            where(:mark => args[0].to_s)
          else
            hash = {}
            hash[:width]  = args[0] unless args[0].nil?
            hash[:height] = args[1] unless args[1].nil?
            where(hash)
          end
        
        else
          where(:mark => nil)
        end

      } # dimentions

    end # included  

  end # Multimedia
  
end # ActsAsFiles