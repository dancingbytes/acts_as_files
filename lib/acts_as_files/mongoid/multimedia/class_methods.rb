# encoding: utf-8
require 'uri'

module ActsAsFiles

  module Multimedia

    module ClassMethods

      def url_to_id(url)

        begin
          uri = URI.parse(url)
        rescue URI::InvalidURIError
          return nil
        end  

        url_path    = ActsAsFiles.config["url_path"]
        shuffle_id  = uri.path.sub(/\.\w+/,'').gsub('/','').scan(/\w\w/)

        time        = shuffle_id[7..10] || []
        machine     = shuffle_id[0..2]  || []
        pid         = shuffle_id[3..4]  || []
        inc         = ((shuffle_id[5..6] || []) << (shuffle_id[11] || []))

        (time << machine << pid << inc).join

      end # url_to_id

      def get_from_url(url)
        where(:_id => url_to_id(url)).first
      end # get_from_url
      
      def split_id(id)

        arr     = id.to_s.scan(/\w\w/)
        time    = arr[0..3]  # 0
        machine = arr[4..6]  # 1
        pid     = arr[7..8]  # 2
        inc     = arr[9..11] # 3

        [time, machine, pid, inc]

      end # split_id
      
      def whole(id)
        
        arr = split_id(id)
        [arr[1..2].join] << arr[3][0..1]

      end # whole

      def rest(id)

        arr = split_id(id)
        arr[0].join << arr[3][2]

      end # rest

      def destroy_each(ids, split_by = ",")

        ids = ids.split(split_by) if ids.is_a?(String)
        ids = [ids] unless ids.is_a?(Array)

        ids.each do |id|
          where(:_id => id).first.try(:destroy)
        end # each

      end # destroy_each

    end # ClassMethods

  end # Multimedia

end # ActsAsFiles