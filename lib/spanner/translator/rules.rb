# frozen_string_literal: true

module Spanner
  module Translator
    # Translation rules
    module Rules
      autoload :Check, "spanner/translator/rules/check"
      autoload :Translation, "spanner/translator/rules/translation"
    end
  end
end
