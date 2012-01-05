# encoding: utf-8

if ActsAsFiles.class_exists?("Multimedia")
  Multimedia.send(:include, ActsAsFiles::Multimedia)
else

  class Multimedia
    include ActsAsFiles::Multimedia
  end

end # if

if defined?(Kaminari)
  require 'kaminari/models/mongoid_extension'
  Multimedia.send :include, Kaminari::MongoidExtension::Document
end