# encoding: utf-8
module ActsAsFiles

  module Multimedia
    
    extend ActiveSupport::Concern
    include Mongoid::Document

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
      field :created_at,    :type => DateTime
      field :position,      :type => Integer
      field :size,          :type => Integer
      field :name

      index :mark,          :background => true   
      index :context_type,  :background => true
      index :context_id,    :background => true
      index :context_field, :background => true   
      index :position,      :background => true
      index :source_id,     :background => true

      scope   :source,  ->(ids) {
        ids = [ids] unless ids.is_a? Array
        any_of({:source_id.in => ids}, {:_id.in => ids})
      }
      
      scope :copies_of, ->(id) {
        where(:source_id => id)
      }

      scope   :sources,  where(:source_id => nil)

      scope   :skip_ids, ->(ids) {
        ids = [ids] unless ids.is_a? Array
        not_in(:_id => ids) unless ids.blank?
      }

      scope   :skip_source, ->(source_id) {
        not_in(:_id => [source_id]) unless source_id.nil?
      }

      scope   :by_field,  ->(field_name) {
        where(:context_field => field_name.to_s)
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

    # methods

    private

    def config
      ActsAsFiles.config
    end # config

  end # Multimedia
  
end # ActsAsFiles


begin
  Multimedia.send(:include, ActsAsFiles::Multimedia)
rescue NameError

  class Multimedia
    include ActsAsFiles::Multimedia
  end

end # begin

# Patch for kaminari
#if defined?(Kaminari)
#  require 'kaminari/models/mongoid_extension'
#  Multimedia.send :include, Kaminari::MongoidExtension::Document
#end