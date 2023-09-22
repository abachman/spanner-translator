# frozen_string_literal: true

module Spanner
  module Translator
    module Rules
      module Translation
        # t.bigint is not supported in spanner, so replace with t.integer, keeping null option if given
        class BigintToInteger < BaseRule
          def on_send(node)
            return unless node.t_bigint?

            new_arguments = [node.arguments[0].source, "limit: 8"]
            conditionally_propagate_argument new_arguments, node, "null"

            @rewriter.replace(node.loc.expression, "t.integer #{new_arguments.join(", ")}")
          end
        end
      end
    end
  end
end
