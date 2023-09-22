# frozen_string_literal: true

module Spanner
  module Translator
    module Rules
      module Translation
        # Replace create_table arguments with sensible spanner options
        class ReplaceCreateTableArgs < BaseRule
          def on_send(node)
            return unless node.create_table?

            # keep table name argument, replace the rest with sensible spanner options
            primary_keys = Spanner::Translator.configuration.default_primary_keys.inspect
            @rewriter.replace(node.arguments[1].source_range, "primary_key: #{primary_keys}, force: :cascade")
          end
        end
      end
    end
  end
end
