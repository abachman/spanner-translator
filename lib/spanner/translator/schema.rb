# frozen_string_literal: true

require "rubocop-ast"

# Utility methods for working with Rails MySQL table schemas
module Spanner
  module Translator
    # Access a Rails formatted db/schema.rb file and return create_table source
    module Schema
      class << self
        def legacy_schema_path
          Spanner::Translator.configuration.db_schema
        end

        def legacy_schema
          raise Spanner::Translator::Error, "db/schema.rb not found" unless File.exist?(legacy_schema_path)

          @legacy_schema ||= File.read(legacy_schema_path)
        end

        # extract the Ruby `create_table` statement for the given table name
        def extract_create_table(table_name)
          legacy_schema.match(/create_table "#{table_name}".*?end$/m)[0]
        end

        # extract the Parser::AST for the given table name,
        # see https://github.com/whitequark/parser/blob/master/doc/AST_FORMAT.md
        def extract_create_table_ast(table_name)
          source = extract_create_table(table_name)
          RuboCop::AST::ProcessedSource.new(source, RUBY_VERSION.to_f).ast
        end
      end
    end
  end
end
