# frozen_string_literal: true

require "json"

module Spanner
  module Translator
    module Rules
      module Translation
        # replace t.column enums with the appropriate t.string and the correct check constraints
        class EnumColumnToStringWithConstraint < BaseRule
          def on_send(node)
            capture_table_name(node)
            return unless node.t_column?

            constraint_name = generate_constraint_name(node)
            unless_seen(constraint_name) do
              @rewriter.replace(node.loc.expression, "t.string #{new_arguments_for_column_definition(node)}")
              constraint = %["#{column_name(node)} IN (#{choices_for_enum_string(node)})"]
              @rewriter.insert_after(node.last_sibling.source_range,
                                     "\n  t.check_constraint #{constraint}, name: \"#{constraint_name}\"")
            end
          end

          private

          def column_name(node)
            JSON.parse(node.arguments[0].source)
          end

          def generate_constraint_name(node)
            table_name = @table_name
            "chk_rails_enum_#{table_name}_#{column_name(node)}"
          end

          def choices_for_enum(node)
            choices = JSON.parse(node.limit_option.value.source)
            # add empty string to options if null is permitted
            choices.unshift("") unless node.null_option_value == "false"
            choices
          end

          def choices_for_enum_string(node)
            choices_for_enum(node).map { |o| "'#{o}'" }.join(", ")
          end

          def new_arguments_for_column_definition(node)
            new_arguments = [%("#{column_name(node)}")]
            conditionally_propagate_argument new_arguments, node, "null"
            conditionally_propagate_argument new_arguments, node, "default"
            new_arguments << "limit: #{choices_for_enum(node).map(&:length).max}"
            new_arguments.join(", ")
          end
        end
      end
    end
  end
end
