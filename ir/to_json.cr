module Ocelot
  module IR
    # Convert IR AST to JSON with proper comma handling
    class ToJson
      @io : IO::Memory

      def initialize(@io = IO::Memory.new)
      end

      def convert(ast : AST) : String
        write_node(ast.root)
        @io.to_s
      end

      private def write_node(node : Node)
        case node.type
        when NodeType::Null
          @io << "null"
        when NodeType::Bool
          @io << (node.value ? "true" : "false")
        when NodeType::Number
          @io << node.value.to_s
        when NodeType::String
          escape_string(@io, node.value.to_s)
        when NodeType::Array
          @io << "["
          first = true
          node.children.try &.each do |child|
            @io << ", " unless first
            first = false
            write_node(child)
          end
          @io << "]"
        when NodeType::Object
          @io << "{"
          first = true
          # Sort children by key for deterministic output
          sorted = (node.children || [] of Node).sort_by { |c| c.key || "" }
          sorted.each do |child|
            @io << ", " unless first
            first = false
            escape_string(@io, child.key || "")
            @io << ": "
            write_node(child)
          end
          @io << "}"
        end
      end

      private def escape_string(io : IO, str : String)
        io << '"'
        str.each_char do |c|
          case c
          when '"' then io << "\\\""
          when '\\' then io << "\\\\"
          when '\n' then io << "\\n"
          when '\r' then io << "\\r"
          when '\t' then io << "\\t"
          else io << c
          end
        end
        io << '"'
      end
    end
  end
end
