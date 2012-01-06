# encoding: utf-8
module ActsAsFiles

  class Manager < ActsAsFiles::BaseManager

    class << self

      def append_file(obj, file_id, field)
        nil
      end # append_file

    end # class << self 

  end # Manager

end # ActsAsFiles