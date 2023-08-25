# frozen_string_literal: true

require "spanner/translator"
require "rails"

module Spanner
  module Translator
    # optional railtie to add the gem's rake tasks
    class Railtie < Rails::Railtie
      railtie_name :spanner_translator

      rake_tasks do
        load File.join(File.expand_path(__dir__), "Rakefile")
      end
    end
  end
end

