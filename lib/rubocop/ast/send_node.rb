# frozen_string_literal: true

module RuboCop
  module AST
    # Spanner-specific extensions for RuboCop::AST::SendNode objects
    class SendNode
      %i[index column bigint datetime timestamp].each do |t_method_name|
        define_method(:"t_#{t_method_name}?") do
          sending_t? && method_name == t_method_name
        end
      end

      def sending_t?
        receiver && receiver.source == "t"
      end

      def create_table?
        method_name == :create_table
      end

      def find_hash_option(option_name)
        return unless arguments.last.hash_type?

        option_name = option_name.to_sym
        arguments.last.children.find do |c|
          c.pair_type? && c.children[0].sym_type? && c.children[0].children[0] == option_name
        end
      end

      def find_hash_option_source(option_name)
        find_hash_option(option_name.to_sym)&.source
      end

      %i[null name unique limit default].each do |option_name|
        define_method(:"#{option_name}_option") do
          find_hash_option(option_name)
        end

        define_method(:"#{option_name}_option_value") do
          find_hash_option(option_name)&.value&.source
        end
      end

      def last_sibling
        parent.children.last
      end
    end
  end
end
