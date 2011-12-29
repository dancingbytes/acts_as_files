# encoding: utf-8
module ActsAsFiles

  class Builder

    def initialize(context, assoc_name)

      @context    = context
      @assoc_name = assoc_name.to_sym
      @obj        = {}
      @fields     = {}
      @max_size   = ""
      @copies     = {}
      @callbacks  = {}
      @parse_from = nil
      
    end # initialize

    def method_missing(symbol, *args)
      return self
    end # method_missing

    def assoc_name
      @assoc_name
    end # assoc_name

    def generate(&block)
      
      self.instance_eval &block if block_given?
      complite

    end # self.generate
    
    def has_one(name, &block)
      
      @target = name.to_sym
      @fields[@target] = {}
      @fields[@target][:relation] = :has_one
      
      self.instance_eval &block if block_given?
      
      @context.class_eval %Q{

        def #{@target}(*args)

          self.#{assoc_name}.by_field('#{@target}').dimentions(*args).first

        end
        
        def #{@target}=(val)
          if val.respond_to?(:id)
            id = val.id
          else
            obj = self.#{assoc_name}.new
            obj.file_upload = val
            obj.save
            id = obj.id
          end
          @#{@target} = id
        end
        
        def #{@target}_id(*args)

          @#{@target} ||= self.#{@target}.try(:id)

        end
        
        def #{@target}_id=(id)

          @#{@target} = id

        end
        

      }
      
    end # has_one

    def has_many(name, &block)
      
      @target = name.to_sym
      @fields[@target] = {}
      @fields[@target][:relation] = :has_many
      
      self.instance_eval &block if block_given?
      
      @context.class_eval %Q{

        def #{@target}(*args)

          imgs = self.#{assoc_name}.by_field('#{@target}').dimentions(*args).asc(:position)

        end
        
        def #{@target.to_s.singularize}_ids

          @#{@target} ||= self.#{@target}.distinct(:_id)

        end
        
        def #{@target.to_s.singularize}_ids=(ids)

          @#{@target} = ids

        end
        

      }
      
    end # has_many
    
    def size!(str)

      if @target
       @fields[@target].merge!({ :max_size => str })
      else
        @max_size = str
      end
      self

    end # size!
    
    def copies(*args)
      
      s = (Hash[*args] rescue {} )
      @target ? @fields[@target].merge!({ :copies => s }) : @copies.merge!(s)
      self
      
    end # copies
    
    def parse_from(field)
      @target ? @fields[@target].merge!({ :parse_from => field.to_sym }) : parse_from.merge!(field.to_sym)
      self
    end
 
    def before_save(proc)
      
      add_callback :before_save, proc
      
    end # before_save

    
    def after_save(proc)
      
      add_callback :after_save, proc
      
    end # after_save
    
    def before_destroy(proc)
      
      add_callback :before_destroy, proc
      
    end # before_destroy

    
    def after_destroy(proc)
      
      add_callback :after_destroy, proc
      
    end # after_destroy
    
    private
    
    def add_callback(name, proc)
      
      h = @target ? @fields[@target][:callbacks] : @callbacks
      h ||= {}
      h[name] ||= []
      h[name] << proc if proc.respond_to?(:call)
      @target ? @fields[@target][:callbacks] = h : @callbacks = h
      
    end # add_callback

    def complite
      
      @obj.merge!({
        :assoc_name => @assoc_name,
        :fields     =>  @fields,
        :copies     =>  @copies,
        :max_size   =>  @max_size,
        :parse_from => @parse_from,
        :callbacks  =>  @callbacks
      })

    end # complite
    
  end # Builder

end # ActsAsFiles