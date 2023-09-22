# frozen_string_literal: true

module Spanner
  module Translator
    module Rules
      module Translation
        # Add t.time :committed_at with allow_commit_timestamp: true before the first t.index
        #
        # FIXME (@abachman): if table has no indexes, this rule will not be applied
        #
        class AddCommittedAtTimestamp < BaseRule
          def on_send(node)
            return if @seen["committed_at"]
            return unless node.t_index?

            committed_at_column = 't.time "committed_at", null: false, allow_commit_timestamp: true'
            @rewriter.insert_before(node.loc.expression, "#{committed_at_column}\n  ")
            @seen["committed_at"] = true
          end
        end
      end
    end
  end
end
