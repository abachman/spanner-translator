# frozen_string_literal: true

require "rubocop-ast"
require "spanner/translator/rules"

module Spanner
  module Translator
    # CLI methods for calling the translator
    module CLI
      class << self
        # process, raising errors if a CheckRule fails
        def process_code!(code,
                          check_classes = Spanner::Translator::Rules::CheckRules.constants,
                          rule_classes = Rules::TranslationRules.constants)
          check_classes.each do |rule_class|
            process_check_rule(Spanner::Translator::Rules::CheckRules.const_get(rule_class), code)
          end

          process_code(code, rule_classes)
        end

        def process_code(code, rule_classes = Spanner::Translator::Rules::TranslationRules.constants)
          rule_classes.each do |rule_class|
            code = process_rule(Spanner::Translator::Rules::TranslationRules.const_get(rule_class), code)
          end
          formatted(code)
        end

        def process_rule(rule_class, code)
          source = RuboCop::AST::ProcessedSource.new(code, 2.7)
          source_buffer = source.buffer
          rewriter = Parser::Source::TreeRewriter.new(source_buffer)
          rule = rule_class.new(rewriter)
          source.ast.each_node { |n| rule.process(n) }
          rewriter.process
        end

        def process_check_rule(rule_class, code)
          source = RuboCop::AST::ProcessedSource.new(code, 2.7)
          rule = rule_class.new(nil)
          source.ast.each_node { |n| rule.process(n) }
          rule.assert!
        end

        private

        def formatted(code)
          code.lines.map do |l|
            case l
            when /(create_table.+|end)$/
              l.strip
            else
              "  #{l.strip}"
            end
          end.join("\n")
        end
      end
    end
  end
end
