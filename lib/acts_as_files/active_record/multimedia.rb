# encoding: utf-8
require 'acts_as_files/active_record/multimedia/class_methods'
require 'acts_as_files/active_record/multimedia/instance_methods'

module ActsAsFiles

  module Multimedia
    
    extend ActiveSupport::Concern

    # metas
    included do

    end # included

  end # Multimedia

end # ActsAsFiles


if ActsAsFiles.class_exists?("Multimedia")
  Multimedia.send(:include, ActsAsFiles::Multimedia)
else
  
  class Multimedia < ActiveRecord::Base
    include ActsAsFiles::Multimedia
  end

end