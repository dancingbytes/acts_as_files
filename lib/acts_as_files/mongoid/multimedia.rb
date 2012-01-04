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


      acts_as_tagging :if => ->(c) { c.source? }

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


      before_save ->(f) { f.updated_at = Time.now.utc }

      before_create   :add_system_tags
      before_save     :initialize_image

      after_create    :create_file
      after_update    :update_file

      after_destroy   :delete_file

    end # included  

    private

    def add_system_tags
      self.tag_sys_list << self.ext unless self.ext.blank?
    end # add_system_tags

  end # Multimedia
  
end # ActsAsFiles


if ActsAsFiles.class_exists?("Multimedia")
  Multimedia.send(:include, ActsAsFiles::Multimedia)
else
  
  class Multimedia
    include ActsAsFiles::Multimedia
  end

end