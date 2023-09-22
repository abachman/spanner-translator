# frozen_string_literal: true

require "json"

module Spanner
  module Translator
    module Rules
      module Translation
        # - set order: { column_name: :asc, datetime: :desc } for each column on every index
        # - propagate name: if explicitly set on index
        # - propagate unique: if explicitly set on index
        # - add null_filtered: true if any column is nullable and index is unique: true
        class AddIndexOptions < BaseRule
          def on_send(node)
            capture_column_nullity(node)
            return unless node.t_index?

            @rewriter.replace(node.loc.expression, "t.index #{new_arguments_for_column_definition(node)}")
          end

          private

          def new_arguments_for_column_definition(node)
            new_arguments = [node.arguments[0].source]
            conditionally_propagate_argument new_arguments, node, "name"
            conditionally_propagate_argument new_arguments, node, "unique"
            new_arguments << order_hash_argument(node)
            conditionally_add_null_filtered_argument new_arguments, node
            new_arguments.join(", ")
          end

          def column_names(node)
            JSON.parse(node.arguments[0].source)
          end

          def order_hash_argument(node)
            order_hash = column_names(node).map do |column_name|
              "#{column_name}: :#{column_name.match?(/[a-z_]+_at$/) ? "desc" : "asc"}"
            end
            "order: { #{order_hash.join(", ")} }"
          end

          # requires capture_column_nullity to be called
          def should_null_filter?(node)
            column_names(node).any? { |c| @column_nullity[c] } &&
              (node.unique_option && node.unique_option.value.source == "true")
          end

          def conditionally_add_null_filtered_argument(new_arguments, node)
            new_arguments << "null_filtered: true" if should_null_filter?(node)
          end
        end
      end
    end
  end
end
