require "json"
module Ocelot
  module IR
    # Convert JSON to IR AST
    class FromJson
      def convert(json : JSON::Any) : AST
        root = convert_node(json)
        AST.new(root)
      end

      private def convert_node(value : JSON::Any) : Node
        raw = value.raw
        case raw
        when Nil
          Node.new(NodeType::Null, nil)
        when Bool
          Node.new(NodeType::Bool, raw)
        when Number
          Node.new(NodeType::Number, raw.to_f64)
        when String
          Node.new(NodeType::String, raw)
        when Array(JSON::Any)
          node = Node.new(NodeType::Array)
          value.as_a.each do |item|
            child = convert_node(item)
            node.add_child(child)
          end
          node
        when Hash(String, JSON::Any)
          node = Node.new(NodeType::Object)
          value.as_h.each do |key, val|
            child = convert_node(val)
            child.key = key
            node.add_child(child)
          end
          node
        else
          Node.new(NodeType::Null)
        end
      end
    end
  end
end
