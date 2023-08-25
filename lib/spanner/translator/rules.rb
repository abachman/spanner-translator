# frozen_string_literal: true

module Spanner
  module Translator
    # Translation rules
    module Rules
      autoload :CheckRules, "spanner/translator/rules/check_rules"
      autoload :TranslationRules, "spanner/translator/rules/translation_rules"
    end
  end
end
