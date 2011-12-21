# encoding: utf-8
module QuickMagick

  class << self

    def exec3(command)

      (result, status) = [`#{command}`, $?]
      unless status.exitstatus == 0
        raise QuickMagick::QuickMagickError, "Error executing command: #{command}\nFailed: #{{:status_code => status, :output => result}.inspect}"
      end
      result

    end # exec3

  end # class << self

end # QuickMagick

module ActsAsFiles

  class ImageProcessor

    def initialize(src)

      src     = src.path if src.respond_to?(:path)
      @image  = ::QuickMagick::Image.read(src).first
      @src    = src

    end # initialize

    def path
      @src
    end # path

    def width
      @width ||= @image.width
    end # width

    def height
      @height ||= @image.height
    end # height

    def resize(cmd)

      @image.append_to_operators("resize", cmd) unless cmd.blank?
      self

    end # resize

    def resize_and_center(w=nil, h=nil)

      if w.nil? && h.nil?
        w, h = self.width, self.height
      elsif w.nil? || h.nil?
        w ||= h; h = w
      end

      if ["png", "gif"].include?(self.format)
        @image.append_basic  "-background transparent"
      else
        @image.append_basic  "-background white"
      end

      @image.append_basic "-compose Copy"
      self.resize("#{w}x#{h}>")
      @image.append_basic "-gravity center"
      @image.append_basic "-extent #{w}x#{h}"
      self

    end # resize_and_center

    def crop(w,h, x=0, y=0)

      l = lambda {|i| i >= 0 ? "+#{i}" : "-#{i.abs}" }
      @image.append_basic "-crop \"#{w}x#{h}#{l.call(x.to_i)}#{l.call(y.to_i)}\!\""
      self

    end # crop

    def thumb(w=nil, h=nil)

      self.format = "png"
      self.resize_and_center(w, h)
      self

    end # thumb

    def watermark(wmf)
      
      w_img = QuickMagick::Image.read(wmf).first
                      
      w = w_img.width
      h = w_img.height              
      x = ((self.width - w) / 2)
      y = ((self.height - h) / 2)
                        
      @image.append_basic "-draw \"image SrcOver #{x},#{y} #{w},#{h} '#{wmf}'\""
      self        

    end # watermark 

    def format=(new_format)

      @format = support_format?(new_format.downcase)
      @image.append_basic "-format #{@format}"
      @format

    end # format=

    def format
      @format ||= @image.format.downcase
    end # format

    def save(target = nil, chmod = 0644)

      @src = (target || @src).gsub(/\.(\w+)$/, ".#{self.format}")
      
      result = (@image.save(@src) rescue false) != false
      File.chmod(chmod, @src) if result && File.exists?(@src)
      result

    end # save

    private

    def support_format?(f)
      ["gif", "jpeg", "jpg", "png"].include?(f) ? f : @image.format.downcase
    end # support_format?

  end # ImageProcessor

end # ActsAsFiles