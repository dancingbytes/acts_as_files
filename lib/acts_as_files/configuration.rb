# encoding: utf-8
module ActsAsFiles

  class Configuration

    include Singleton

    def initialize # instance
      @config = {}
      
      development do
        
        file_size_limit 32.megabytes
        url_path '/public'
        thumb_url_path '/public/thumb'
        local_path 'public'
        local_thumb_path 'public/thumb'
        local_source_path 'src'
        
      end
      
      config_file = File.join(Rails.root, "config", "acts_as_files.rb")
      self.instance_eval(File.read(config_file), config_file) if File.exists?(config_file)
      
    end # initialize
    
    def development(&block)
      @env = "development"
      @config[@env] ||= {}
      self.instance_eval &block# if block_given?
    end # development
    
    def production(&block)
      @env = "production"
      @config[@env] ||= {}
      self.instance_eval &block if block_given?
    end # production
    
    def test(&block)
      @env = "test"
      @config[@env] ||= {}
      self.instance_eval &block if block_given?
    end # test
    
    def config
      @config[@env]
    end
    
    def method_missing(symbol, *args)
      
      value = args[0]
      
      if [:file_size_limit, :url_path, :thumb_url_path].include?(symbol)
        
        @config[@env][symbol] = value
      
      elsif [:local_path,  :local_thumb_path, :local_source_path].include?(symbol)
        
        @config[@env][symbol] = File.expand_path(value, Rails.root)
        
      else
        puts "No method `#{symbol}` for ActsAsFiles::Configuration.instance"
      end
      
      self
      
    end # method_missing

  end # Configuration

end # ActsAsFile