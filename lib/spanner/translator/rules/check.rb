# frozen_string_literal: true

require "spanner/translator/rules/base_rule"

module Spanner
  module Translator
    module Rules
      module Check # rubocop:disable Style/Documentation
        autoload :HasAnyIndex, "spanner/translator/rules/check/has_any_index"
      end
    end
  end
end
