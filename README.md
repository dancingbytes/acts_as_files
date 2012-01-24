Acts as files
Author: redfield (up.redfield@gmail.com), Tyralion (piliaiev@gmail.com)
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

Copyright (c) 2012 DansingBytes.ru

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
