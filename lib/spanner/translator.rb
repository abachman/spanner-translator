# frozen_string_literal: true

require "spanner/translator/railtie" if defined?(Rails::Railtie)

module Spanner
  # MySQL to Google Cloud Spanner Rails create_table statement translator
  module Translator
    class Error < StandardError; end

    autoload :CLI, "spanner/translator/cli"
    autoload :Configuration, "spanner/translator/configuration"
    autoload :Rules, "spanner/translator/rules"
    autoload :Schema, "spanner/translator/schema"
    autoload :VERSION, "spanner/translator/version"

    class << self
      def configure
        yield(configuration)
      end

      def configuration
        @configuration ||= Configuration.new
      end
    end
  end
end
