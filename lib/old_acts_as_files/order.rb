# encoding: utf-8
module ActsAsFiles

  module Order

    module ClassMethods
    end # ClassMethods

    module InstanceMethods
      
      def increment_position

        return unless in_list?
        self.inc(:position, 1)
        #self.position = self.position.to_i + 1
        #self.class.where(:source_id => self.source_id).update_all(
        #  :position => self.position)

      end # increment_position
      
      def decrement_position

        return unless in_list?
        
        self.inc(:position, -1)
        #self.position = self.position.to_i - 1
        #self.class.where(:source_id => self.source_id).update_all(
        #  :position => self.position)

      end # decrement_position
      
      def move_to_bottom

        return unless in_list?
        decrement_positions_on_lower_items
        assume_bottom_position

      end # move_to_bottom
      
      def move_to_top

        return unless in_list?
        increment_positions_on_higher_items
        assume_top_position

      end # move_to_top
      
      def remove_from_list

        return unless in_list?
        decrement_positions_on_lower_items
        self.position = nil
        self.class.where(:source_id => self.source_id).update_all(
          :position => self.position)

      end # remove_from_list
      
      def in_list?
        !self.position.nil?
      end # in_list?

      private
      
      def add_to_list_bottom
        self.position = (bottom_item.try(:position) || 0).to_i + 1
      end # add_to_list_bottom
      
      def bottom_item(except = nil)
        
        conditions = {}
        conditions= {:context_type => self.context_type, 
                     :context_id => self.context_id,
                     :mark => self.mark,
                     :context_field => self.context_field
                    }
        (conditions["_id.ne".to_sym] = except.id) if except
        self.class.where(conditions).desc(:position).first

      end # bottom_item
      
      def decrement_positions_on_lower_items

        return unless in_list?
        self.class.where(
          :source_id.ne => self.source_id,
          :context_type => self.context_type,
          :context_field => self.context_field,
          :context_id => self.context_id,
          :position.gt => self.position.to_i
          ).each do |m|
            m.inc(:position, -1)
          end # each

      end # decrement_positions_on_lower_items
      
      def increment_positions_on_higher_items

        return unless in_list?
        self.class.where(
          :source_id.ne => self.source_id,
          :context_type => self.context_type,
          :context_field => self.context_field,
          :context_id => self.context_id,
          :position.lt => self.position.to_i
          ).each do |m|
            m.inc(:position, 1)
          end # each

      end # increment_positions_on_higher_items
      
      def assume_bottom_position

        self.position = (bottom_item(self).try(:position) || 0).to_i + 1
        self.class.where(self.source_id).update_all(:position => self.position)

      end # assume_bottom_position
      
      def assume_top_position

        self.position = 1
        self.class.where(self.source_id).update_all(:position => self.position)

      end # assume_top_position
      
      def eliminate_current_position
        decrement_positions_on_lower_items if in_list?
      end # eliminate_current_position

    end # InstanceMethods

  end # Order

end # ActsAsFiles