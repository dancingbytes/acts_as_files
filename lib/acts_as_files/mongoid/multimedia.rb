# encoding: utf-8
module ActsAsFiles

  module Multimedia
    
    def test2
      puts "Multimedia in aaf [test2]"
    end # test2

    def test
      puts "Multimedia in aaf [test]"
    end # test 

  end # Multimedia
  
end # ActsAsFiles


begin

  Multimedia.send(:include, Mongoid::Document)
  Multimedia.send(:include, ActsAsFiles::Multimedia)

rescue NameError

  class Multimedia
    
    include Mongoid::Document
    include ActsAsFiles::Multimedia

  end # Multimedia

end