require "json"
require "../format/compact_reader"

module Ocelot
  module Find
    def self.find(input_path : String, query : JSON::Any, output_path : String)
      slice = File.read(input_path).to_slice
      reader = Format::CompactBinaryReader.new(slice)
      ast = reader.read
      
      results = search(ast.root, query)
      
      wrapper = IR::Node.new(IR::NodeType::Object)
      results.each_with_index do |node, idx|
        node.key = idx.to_s
        wrapper.add_child(node)
      end
      json = IR::ToJson.new.convert(IR::AST.new(wrapper))
      File.write(output_path, json)
    end
    
    private def self.search(node : IR::Node, query : JSON::Any) : Array(IR::Node)
      results = [] of IR::Node
      if matches?(node, query)
        results << node
      end
      node.children.try &.each do |child|
        results.concat(search(child, query))
      end
      results
    end
    
    private def self.matches?(node : IR::Node, query : JSON::Any) : Bool
      raw = query.raw
      case raw
      when Hash(String, JSON::Any)
        raw.each do |key, qval|
          child = node.children.try &.find { |c| c.key == key }
          return false unless child
          return false unless matches?(child, qval)
        end
        true
      when String
        node.value == raw
      when Number
        node.value == raw.to_f64
      when Bool
        node.value == raw
      else
        false
      end
    end
  end
end
