# encoding: utf-8
module ActsAsFiles

  module Multimedia
    
    extend ActiveSupport::Concern

    # metas
    included do

    end # included

  end # Multimedia

end # ActsAsFiles


begin
  Multimedia.send(:include, ActsAsFiles::Multimedia)
rescue NameError

  class Multimedia < ActiveRecord::Base
    include ActsAsFiles::Multimedia
  end

end # begin