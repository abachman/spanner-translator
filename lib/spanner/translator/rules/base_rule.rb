# frozen_string_literal: true

require "rubocop-ast"
require "rubocop/ast/send_node"

module Spanner
  module Translator
    module Rules
      class BaseRule < Parser::AST::Processor # rubocop:disable Style/Documentation
        include RuboCop::AST::Traversal

        # rubocop:disable Lint/MissingSuper
        def initialize(rewriter)
          @rewriter = rewriter
          @seen ||= {}
          @column_nullity ||= {}
        end
        # rubocop:enable Lint/MissingSuper

        def create_range(begin_pos, end_pos)
          Parser::Source::Range.new(@rewriter.source_buffer, begin_pos, end_pos)
        end

        def capture_table_name(node)
          @table_name = node.arguments[0].source.tr('"', "") if node.method_name == :create_table
        end

        RAILS_COLUMN_TYPES = %i[bigint string text integer float decimal
                                datetime timestamp time date binary boolean].freeze

        # track every columns' null acceptance
        def capture_column_nullity(node)
          is_typed_column_node = node.receiver &&
                                 node.receiver.source == "t" &&
                                 RAILS_COLUMN_TYPES.include?(node.method_name)
          return unless is_typed_column_node

          column_name = node.arguments[0].source.tr('"', "")
          null_option = node.find_hash_option(:null)

          # "may be null" means this column is not defined with explicit "null: false"
          @column_nullity[column_name] = null_option&.value&.source != "false"
        end

        def any_index?
          @seen["index"]
        end

        def unless_seen(condition)
          return if @seen[condition]

          yield
          @seen[condition] = true
        end

        def conditionally_propagate_argument(arguments, node, name)
          arguments << node.find_hash_option_source(name) if node.find_hash_option(name)
        end
      end
    end
  end
end
