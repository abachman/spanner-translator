# frozen_string_literal: true

require "spanner/translator/rules/base_rule"

module Spanner
  module Translator
    module Rules
      module Translation # rubocop:disable Style/Documentation
        autoload :AddCommittedAtTimestamp, "spanner/translator/rules/translation/add_committed_at_timestamp"
        autoload :AddIdColumn, "spanner/translator/rules/translation/add_id_column"
        autoload :AddIndexOptions, "spanner/translator/rules/translation/add_index_options"
        autoload :BigintToInteger, "spanner/translator/rules/translation/bigint_to_integer"
        autoload :EnumColumnToStringWithConstraint,
                 "spanner/translator/rules/translation/enum_column_to_string_with_constraint"
        autoload :ReplaceCreateTableArgs, "spanner/translator/rules/translation/replace_create_table_args"
        autoload :TimeColumnsToTime, "spanner/translator/rules/translation/time_columns_to_time"
      end
    end
  end
end
