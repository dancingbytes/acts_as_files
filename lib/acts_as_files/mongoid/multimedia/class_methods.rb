# encoding: utf-8
module ActsAsFiles

  module MultimediaMongoid

    module ClassMethods

      def url_to_id(url)

        begin
          uri = ::URI.parse(url)
        rescue ::URI::InvalidURIError
          return
        end

        return if uri.path.nil?

        shuffle_id  = uri.path.sub(/\.\w+/,'').gsub('/','').scan(/\w\w/)

        time        = shuffle_id[7..10] || []
        machine     = shuffle_id[0..2]  || []
        pid         = shuffle_id[3..4]  || []
        inc         = ((shuffle_id[5..6] || []) << (shuffle_id[11] || []))

        (time << machine << pid << inc).join

      end # url_to_id

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
      alias :diff :whole

      def rest(id)

        arr = split_id(id)
        arr[0].join << arr[3][2]

      end # rest

      def url(id, sid, ext, looking_for = nil)

        (
          if looking_for == :thumb
            [::ActsAsFiles.config["thumb_url_path"], diff(sid), basename(id, sid, ext, :thumb)]
          else
            [::ActsAsFiles.config["url_path"], diff(id), basename(id, sid, ext)]
          end
        ).flatten.join("/")

      end # url

      private

      def basename(id, sid, ext, looking_for = nil)

        case(looking_for)
          when :thumb   then "#{rest(sid)}.png"
          when :source  then "#{rest(sid)}.#{ext}"
          else "#{rest(id)}.#{ext}"
        end

      end # basename

    end # ClassMethods

  end # Multimedia

end # ActsAsFiles
