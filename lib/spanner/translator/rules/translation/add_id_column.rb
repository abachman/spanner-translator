# frozen_string_literal: true

module Spanner
  module Translator
    module Rules
      module Translation
        # Add explicit primary key column
        class AddIdColumn < BaseRule
          def on_send(node)
            return if @seen["primary_key"]
            return unless node.sending_t? # we assume every create_table has at least one t. statement

            @rewriter.insert_before(node.loc.expression, "t.integer \"id\", limit: 8, null: false\n  ")
            @seen["primary_key"] = true
          end
        end
      end
    end
  end
end
