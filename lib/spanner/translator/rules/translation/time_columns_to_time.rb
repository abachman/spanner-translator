# frozen_string_literal: true

module Spanner
  module Translator
    module Rules
      module Translation
        # convert t.datetime and t.timestamp to t.time, keeping null option if given
        class TimeColumnsToTime < BaseRule
          def on_send(node)
            return unless node.t_datetime? || node.t_timestamp?

            new_arguments = [node.arguments[0].source]
            conditionally_propagate_argument new_arguments, node, "null"

            @rewriter.replace(node.loc.expression, "t.time #{new_arguments.join(", ")}")
          end
        end
      end
    end
  end
end
