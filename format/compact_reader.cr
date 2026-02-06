require "./compact"

module Ocelot
  module Format
    # Compact binary format reader for Ocelot v2
    class CompactBinaryReader
      MAGIC = "OCE2"
      VERSION = 2_u32
      MAGIC_FOOTER = "OCELOTEND"
      
      @slice : Bytes
      @string_table : CompactStringTable
      @records : Array(CompactNodeRecord)
      @value_pool : Bytes
      @footer_offset : UInt64
      @node_count : UInt64
      @string_table_size : UInt64
      
      def initialize(@slice : Bytes)
        @string_table = CompactStringTable.new
        @records = [] of CompactNodeRecord
        @value_pool = Bytes.empty
        @footer_offset = 0_u64
        @node_count = 0_u64
        @string_table_size = 0_u64
      end
      
      def read : IR::AST
        parse_header
        parse_sections
        build_ast
      end
      
      getter :node_count, :string_table_size, :string_table
      
      private def parse_header
        raise "File too small" if @slice.size < 32
        
        magic = String.new(@slice[0, 4])
        raise "Invalid magic: #{magic}" unless magic == MAGIC
        
        version = IO::Memory.new(@slice[4, 4]).read_bytes(UInt32, IO::ByteFormat::LittleEndian)
        raise "Unsupported version: #{version}" unless version == VERSION
        
        @node_count = IO::Memory.new(@slice[8, 8]).read_bytes(UInt64, IO::ByteFormat::LittleEndian)
        @string_table_size = IO::Memory.new(@slice[16, 8]).read_bytes(UInt64, IO::ByteFormat::LittleEndian)
        @footer_offset = IO::Memory.new(@slice[24, 8]).read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      end
      
      private def parse_sections
        header_size = 32_u64
        
        string_table_start = header_size
        string_table_end = string_table_start + @string_table_size
        
        if @string_table_size > 0
          @string_table = CompactStringTable.from_bytes(@slice[string_table_start, @string_table_size])
        end
        
        # Parse NRT - each record is 16 bytes
        nrt_start = string_table_end
        nrt_size = @node_count * 16
        
        if nrt_size > 0
          offset = nrt_start
          @node_count.times do
            break if offset + 16 > @slice.size
            record = CompactNodeRecord.from_bytes(@slice[offset, 16])
            @records << record
            offset += 16
          end
        end
        
        # Value pool
        value_pool_start = nrt_start + nrt_size
        value_pool_end = @footer_offset
        if value_pool_start < value_pool_end
          @value_pool = @slice[value_pool_start, value_pool_end - value_pool_start]
        end
      end
      
      private def build_ast : IR::AST
        if @records.empty?
          return IR::AST.new(IR::Node.new(IR::NodeType::Null))
        end
        
        # Create nodes
        nodes = Array(IR::Node?).new(@records.size, nil)
        
        @records.each_with_index do |record, i|
          node = create_node(record)
          nodes[i] = node
        end
        
        # Link parent-child relationships
        @records.each_with_index do |record, i|
          node = nodes[i]?
          next unless node
          
          if record.has_parent? && record.parent_id < nodes.size && record.parent_id != i
            parent = nodes[record.parent_id]?
            if parent
              parent.add_child(node)
            end
          end
        end
        
        # Find root
        root = nil
        @records.each_with_index do |record, i|
          if record.parent_id == 0 && i > 0
            # This might be the root if it has no parent
          end
          if i == 0 || !record.has_parent?
            root = nodes[i]?
            break if root
          end
        end
        
        root ||= nodes[0]?
        root ||= IR::Node.new(IR::NodeType::Null)
        
        IR::AST.new(root)
      end
      
      private def create_node(record : CompactNodeRecord) : IR::Node
        type = case record.type
               when NodeType::Null then IR::NodeType::Null
               when NodeType::Bool then IR::NodeType::Bool
               when NodeType::Int, NodeType::Float then IR::NodeType::Number
               when NodeType::String then IR::NodeType::String
               when NodeType::Array then IR::NodeType::Array
               when NodeType::Object then IR::NodeType::Object
               else IR::NodeType::Null
               end
        
        # Get key
        key = nil
        if record.has_key? && record.key_id < @string_table.size
          key = @string_table.get_string(record.key_id)
        end
        
        # Get value
        value = case record.type
                when NodeType::Null
                  nil
                when NodeType::Bool
                  record.value_ref == 1
                when NodeType::Int
                  record.value_ref.to_i64
                when NodeType::Float
                  if @value_pool.size >= record.value_ref + 8
                    IO::Memory.new(@value_pool[record.value_ref, 8]).read_bytes(Float64, IO::ByteFormat::LittleEndian)
                  else
                    0.0
                  end
                when NodeType::String
                  @string_table.get_string(record.value_ref)
                else
                  nil
                end
        
        IR::Node.new(type, value, key)
      end
    end
  end
end
