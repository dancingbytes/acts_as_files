# encoding: utf-8
require 'acts_as_files/mongoid/multimedia/class_methods'

module ActsAsFiles

  module Multimedia

    extend  ::ActiveSupport::Concern

    # metas
    included do

      include ::Mongoid::Document

      include ::ActsAsFiles::MultimediaBase::InstanceMethods
      extend  ::ActsAsFiles::MultimediaMongoid::ClassMethods

      field :source_id
      field :ext
      field :mark
      field :width,         :type => Integer,   :default => 0
      field :height,        :type => Integer,   :default => 0
      field :context_type
      field :context_id
      field :context_field
      field :mime_type
      field :updated_at,    :type => Time
      field :position,      :type => Integer
      field :size,          :type => Integer,   :default => 0
      field :name

      index({

        position:       1,
        context_type:   1,
        context_id:     1,
        context_field:  1,
        mark:           1,
        source_id:      1

      }, {
        name:       'multimedia_indx',
        background: true
      })

      index({

        position:       1,
        context_type:   1,
        context_id:     1,
        context_field:  1,
        mark:           1

      }, {
        name:       'multimedia_indx2',
        background: true
      })

      index({

        context_type:   1,
        context_id:     1,
        context_field:  1,
        source_id:      1

      }, {
        name:       'multimedia_indx3',
        background: true
      })

      index({ updated_at: 1 }, background: true )
      index({ source_id:  1 }, background: true )

      scope   :source,  ->(ids = []) {
        ids = [ids] unless ids.is_a? ::Array
        any_of({:source_id.in => ids}, {:_id.in => ids})
      }

      scope :copies_of, ->(id) {
        where(:source_id => id)
      }

      scope   :sources,  ->() {
        where(:source_id => nil)
      }

      scope   :skip_ids, ->(ids = []) {

        ids = [ids] unless ids.is_a? ::Array
        ids = ids.uniq.compact
        ids.empty? ? self.criteria : where(:id.nin => ids)

      }

      scope   :by_field,  ->(field_name) {
        where(:context_field => field_name.to_s)
      }

      scope   :by_context,  ->(obj) {
        where(:context_type => obj.class.to_s, :context_id => obj.id)
      }

      scope   :general,  ->() {
        by_field('')
      }

      scope   :dimentions, ->(*args) {

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

    end # included

  end # Multimedia

end # ActsAsFiles
