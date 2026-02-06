module Ocelot
  module IR
    # Node types matching binary format
    enum NodeType
      Null
      Bool
      Number
      String
      Array
      Object
    end

    # Represents a node in the intermediate representation
    class Node
      property type : NodeType
      property parent : Node?
      property key : String?
      property value : Value
      property children : Array(Node)?
      property id : UInt64 = 0

      def initialize(@type : NodeType, @value : Value = nil, @key : String? = nil)
        @children = nil
        @parent = nil
      end

      def add_child(child : Node)
        @children ||= [] of Node
        if child.parent != self
          @children.not_nil! << child
          child.parent = self
        end
      end
    end

    # Value types
    alias Value = (Bool | Float64 | Int64 | String | Nil)

    # AST for JSON
    class AST
      property root : Node

      def initialize(@root : Node)
      end
    end

    # Visitor for traversing AST
    abstract class Visitor
      abstract def visit(node : Node)
    end
  end
end
