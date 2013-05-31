# encoding: utf-8
require 'acts_as_files/active_record/multimedia/class_methods'

module ActsAsFiles

  module Multimedia
    
    extend ::ActiveSupport::Concern

    # metas
    included do

      include ::ActsAsFiles::MultimediaBase::InstanceMethods
      extend  ::ActsAsFiles::MultimediaAR::ClassMethods

      # Защищенные параметры
      # attr_protected  :source_id,
      #                 :ext,
      #                 :mark,
      #                 :width,
      #                 :height,
      #                 :context_type,
      #                 :context_id,
      #                 :context_field,
      #                 :mime_type,
      #                 :updated_at,
      #                 :position,
      #                 :size

      scope   :source,  ->(ids = []) {
        ids = [ids] unless ids.is_a? ::Array
        where({:source_id => 0, :id => ids })
      }
      
      scope :copies_of, ->(id) {
        where(:source_id => id)
      }

      scope   :sources,  -> { where(:source_id => 0) }

      scope   :skip_ids, ->(ids = []) {
        
        ids = [ids] unless ids.is_a? ::Array
        ids = ids.uniq.compact
        ids.empty? ? nil : where("`id` NOT IN (#{ids.join(',')})") 
          
      }

      scope   :by_field,  ->(field_name) {
        where(:context_field => field_name.to_s)
      }

      scope   :by_context,  ->(obj) {
        where(:context_type => obj.class.to_s, :context_id => obj.id)
      }

      scope   :general,     -> { by_field('') }
      scope   :dimentions,  ->(*args) {

        return sources if args.length == 0
        
        if (args[0].is_a?(::String) || args[0].is_a?(::Symbol))
          where(:mark => args[0].to_s)
        else
          hash = {}
          hash[:width]  = args[0] unless args[0].nil?
          hash[:height] = args[1] unless args[1].nil?
          where(hash)
        end
        
      } # dimentions

      scope :asc, ->(field) {
        order("#{field} ASC")
      } # asc

      scope :desc, ->(field) {
        order("#{field} DESC")
      } # desc

    end # included

  end # Multimedia

end # ActsAsFiles
