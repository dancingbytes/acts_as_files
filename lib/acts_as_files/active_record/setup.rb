# encoding: utf-8

if ActsAsFiles.class_exists?("Multimedia")
  Multimedia.send(:include, ActsAsFiles::Multimedia)
else

  class Multimedia < ActiveRecord::Base
    include ActsAsFiles::Multimedia
  end

end # if