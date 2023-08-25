# frozen_string_literal: true

module Spanner
  module Translator
    # Configuration
    class Configuration
      attr_accessor :rules, :checks, :db_schema
      attr_reader :default_primary_keys

      def initialize
        @rules = nil
        @checks = nil
        @db_schema = "db/schema.rb"
        @default_primary_keys = ["id"]
      end

      # Set primary key column(s), make sure it is an array of symbols
      def default_primary_keys=(value)
        @default_primary_keys = value.is_a?(Array) ? value : [value]
        @default_primary_keys.map!(&:to_sym)
      end
    end
  end
end
