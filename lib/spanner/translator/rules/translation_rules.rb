# frozen_string_literal: true

require "json"
require_relative "./base_rule"

module Spanner
  module Translator
    module Rules
      module TranslationRules
        # Replace create_table arguments with sensible spanner options
        class ReplaceCreateTableArgs < BaseRule
          def on_send(node)
            return unless node.create_table?

            # keep table name argument, replace the rest with sensible spanner options
            primary_keys = Spanner::Translator.configuration.default_primary_keys.inspect
            @rewriter.replace(node.arguments[1].source_range, "primary_key: #{primary_keys}, force: :cascade")
          end
        end

        # t.bigint is not supported in spanner, so replace with t.integer, keeping null option if given
        class BigintToInteger < BaseRule
          def on_send(node)
            return unless node.t_bigint?

            new_arguments = [node.arguments[0].source, "limit: 8"]
            new_arguments << "null: #{node.null_option.value.source}" if node.null_option

            @rewriter.replace(node.loc.expression, "t.integer #{new_arguments.join(", ")}")
          end
        end

        # convert t.datetime and t.timestamp to t.time, keeping null option if given
        class TimeColumnsToTime < BaseRule
          def on_send(node)
            return unless node.t_datetime? || node.t_timestamp?

            new_arguments = [node.arguments[0].source]
            new_arguments << "null: #{node.null_option.value.source}" if node.null_option

            @rewriter.replace(node.loc.expression, "t.time #{new_arguments.join(", ")}")
          end
        end

        # Add explicit primary key column
        class AddIdColumn < BaseRule
          def on_send(node)
            return if @seen["primary_key"]
            return unless node.t_index? # we assume every create_table has at least one index

            first_sibling = node.parent.children.first
            @rewriter.insert_before(first_sibling.source_range, "t.integer \"id\", limit: 8, null: false\n  ")
            @seen["primary_key"] = true
          end
        end

        # Add t.time :committed_at with allow_commit_timestamp: true before the first t.index
        class InsertCommittedAtTimestamp < BaseRule
          def on_send(node)
            return if @seen["committed_at"]
            return unless node.t_index?

            committed_at_column = 't.time "committed_at", null: false, allow_commit_timestamp: true'
            @rewriter.insert_before(node.loc.expression, "#{committed_at_column}\n  ")
            @seen["committed_at"] = true
          end
        end

        # replace t.column enums with the appropriate t.string and the correct check constraints
        class EnumColumnToStringWithConstraint < BaseRule
          def on_send(node)
            capture_table_name(node)
            return unless node.t_column?

            column_name = node.arguments[0].source.tr('"', "")
            table_name = @table_name
            constraint_name = "chk_rails_enum_#{table_name}_#{column_name}"
            return if @seen[constraint_name]

            choices_for_enum = JSON.parse(node.limit_option.value.source)
            last_sibling = node.parent.children.last

            # new arguments for the column definition
            new_arguments = [%("#{column_name}")]
            new_arguments << "null: #{node.null_option.value.source}" if node.null_option
            new_arguments << "default: #{node.default_option.value.source}" if node.default_option
            new_arguments << "limit: #{choices_for_enum.map(&:length).max}"

            @rewriter.replace(node.loc.expression, "t.string #{new_arguments.join(", ")}")

            # add empty string to options if null is permitted
            choices_for_enum.unshift("") if !node.null_option || node.null_option.value.source == "true"
            choices_for_enum_string = choices_for_enum.map { |o| "'#{o}'" }.join(", ")
            constraint = %["#{column_name} IN (#{choices_for_enum_string})"]
            @rewriter.insert_after(last_sibling.source_range,
                                   "\n  t.check_constraint #{constraint}, name: \"#{constraint_name}\"")
            @seen[constraint_name] = true
          end
        end

        # Set order: { column_name: :asc, datetime: :desc } for each column on every index
        class IndexWithOrders < BaseRule
          def on_send(node)
            capture_column_nullity(node)

            return unless node.t_index?

            column_names = JSON.parse(node.arguments[0].source)
            order_hash = column_names.map { |c| "#{c}: :#{c.match?(/[a-z_]+_at$/) ? "desc" : "asc"}" }
            any_column_null = column_names.any? { |c| @column_nullity[c] }

            new_arguments = [node.arguments[0].source]
            new_arguments << "name: #{node.name_option.value.source}" if node.name_option
            new_arguments << "unique: #{node.unique_option.value.source}" if node.unique_option
            new_arguments << "order: { #{order_hash.join(", ")} }"
            new_arguments << "null_filtered: true" if any_column_null

            @rewriter.replace(node.loc.expression, "t.index #{new_arguments.join(", ")}")
          end
        end
      end
    end
  end
end
