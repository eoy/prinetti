require 'rails/generators'
require 'rails/generators/named_base'

module Prinetti
  module Generators

    class PrinettiGenerator < Rails::Generators::Base
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      def create_install
        say "creating initializer..."
        template 'prinetti.rb', 'config/initializers/prinetti.rb'
      end
    end

  end
end