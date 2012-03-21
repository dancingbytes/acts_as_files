Acts as files
======


File upload manager for rails.

### Supported environment

Ruby:   1.9.2, 1.9.3

Rails:  3.0, 3.1, 3.2

ORM:    ActiveRecord, MondgoID


### DSL example

    acts_as_files do
    
      has_one :pic do
    
        # default "200x200^"
    
        default do |file|
          file.change_file.format('jpg')
        end  
    
        # copies :small, "123x123^"
    
        copies :small do |file| 
          file.change_file 
        end
    
        copies :medium, "300x300^"
    
      end # has_one
    
      has_many :images do
    
        parse_from :description
    
        # default "123x123^"
    
        default do |file|
          file.change_file.format('png')
        end  
    
        # copies :small, "123x123^"
    
        copies :small do |file| 
          file.change_file 
        end
    
        copies :medium, "300x300^"
    
      end # has_many 
    
    end # acts_as_files

### License

Authors: redfield (up.redfield@gmail.com), Tyralion (piliaiev@gmail.com)

Copyright (c) 2012 DansingBytes.ru, released under the BSD license