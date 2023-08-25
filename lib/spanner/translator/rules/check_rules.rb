# frozen_string_literal: true

require_relative "./base_rule"

module Spanner
  module Translator
    module Rules
      module CheckRules
        # Check if table has any t.index statement
        class HasAnyIndex < BaseRule
          def on_send(node)
            return unless node.t_index?

            @seen["index"] = true
          end

          def assert!
            raise "table has no index" unless any_index?
          end
        end
      end
    end
  end
end
