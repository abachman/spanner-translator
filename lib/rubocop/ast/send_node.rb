# frozen_string_literal: true

module RuboCop
  module AST
    # Spanner-specific extensions for RuboCop::AST::SendNode objects
    class SendNode
      %i[index column bigint datetime timestamp].each do |t_method_name|
        define_method(:"t_#{t_method_name}?") do
          receiver && receiver.source == "t" && method_name == t_method_name
        end
      end

      def create_table?
        method_name == :create_table
      end

      def find_hash_option(option_name)
        return unless arguments.last.hash_type?

        arguments.last.children.find do |c|
          c.pair_type? && c.children[0].sym_type? && c.children[0].children[0] == option_name
        end
      end

      %i[null name unique limit default].each do |option_name|
        define_method(:"#{option_name}_option") do
          find_hash_option(option_name)
        end
      end
    end
  end
end
