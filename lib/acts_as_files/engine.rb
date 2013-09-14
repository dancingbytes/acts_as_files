# encoding: utf-8
module ActsAsFiles

  class Engine < ::Rails::Engine

    initializer :append_migrations do |app|

      unless app.root.to_s.match root.to_s

        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end

      end # unless

    end # initializer

  end # Engine

end # ActsAsFiles
