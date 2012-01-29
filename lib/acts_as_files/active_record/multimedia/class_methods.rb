# encoding: utf-8
module ActsAsFiles

  module MultimediaAR

    module ClassMethods

      def record_id(w, r)
        w.reverse.to_i(16) * ::ActsAsFiles.config["files_per_folder"] + r.to_i - 1
      end # record_id

      def url_to_id(url)

        begin
          uri = ::URI.parse(url)
        rescue ::URI::InvalidURIError
          return
        end 

        return if uri.path.nil?

        rgx = /([\/[0-9a-f]]+)(\/\d+)\.\w+$/
        
        uri.path.scan(rgx) { |result|

          whole = clear_string(result[0])
          if ( whole.length == clear_array(result[0]).length )
            return record_id( whole, clear_string(result[1]) )
          end # if

        } # scan
        nil

      end # url_to_id  

      def whole(numb)
        numb / ::ActsAsFiles.config["files_per_folder"]
      end # whole

      def rest(numb)
        (numb % ::ActsAsFiles.config["files_per_folder"]) + 1
      end # rest

      def diff(numb)
        whole(numb).to_s(16).split(//).reverse
      end # diff

      private

      def clear_string(str)
        str.gsub("/", "")
      end # clear_string

      def clear_array(arr)
        arr.split("/").drop(1)
      end # clear_array

    end # ClassMethods
    
  end # MultimediaAR
  
end # ActsAsFiles