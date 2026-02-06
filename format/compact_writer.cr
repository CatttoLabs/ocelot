require "./compact"

module Ocelot
  module Format
    # Compact binary format writer for Ocelot v2
    class CompactBinaryWriter
      MAGIC = "OCE2"
      VERSION = 2_u32
      MAGIC_FOOTER = "OCELOTEND"
      
      @string_table : CompactStringTable
      @records : Array(CompactNodeRecord)
      @value_pool : IO::Memory
      @node_list : Array(IR::Node)
      
      def initialize
        @string_table = CompactStringTable.new
        @records = [] of CompactNodeRecord
        @value_pool = IO::Memory.new
        @node_list = [] of IR::Node
      end
      
      def write(ast : IR::AST) : Bytes
        collect_nodes(ast.root)
        build_records()
        serialize()
      end
      
      private def collect_nodes(node : IR::Node)
        node_id = @node_list.size.to_u32
        @node_list << node
        node.id = node_id
        
        if node.value.is_a?(String)
          @string_table.get_id(node.value.as(String))
        end
        if node.key
          @string_table.get_id(node.key.not_nil!)
        end
        
        node.children.try &.each { |child| collect_nodes(child) }
      end
      
      private def build_records()
        @node_list.each do |node|
          node_id = node.id
          
          type = case node.type
                 when IR::NodeType::Null then NodeType::Null
                 when IR::NodeType::Bool then NodeType::Bool
                 when IR::NodeType::Number 
                   if node.value.is_a?(Int64) && node.value.as(Int64) >= 0 && node.value.as(Int64) < 0xFFFFFF
                     NodeType::Int
                   elsif node.value.is_a?(Int32) && node.value.as(Int32) >= 0 && node.value.as(Int32) < 0xFFFFFF
                     NodeType::Int
                   else
                     NodeType::Float
                   end
                 when IR::NodeType::String then NodeType::String
                 when IR::NodeType::Array then NodeType::Array
                 when IR::NodeType::Object then NodeType::Object
                 else NodeType::Null
                 end
          
          flags = 0_u8
          flags |= 0x01 if node.parent
          flags |= 0x02 if node.key
          flags |= 0x04 if node.type == IR::NodeType::Array || node.type == IR::NodeType::Object
          
          type_flags = ((type.value.to_u8) << 4) | flags
          
          parent_id = if node.parent
            node.parent.not_nil!.id.to_u32
          else
            0_u32
          end
          
          key_id = 0_u32
          if node.key
            key_id = @string_table.get_id(node.key.not_nil!)
          end
          
          value_ref = 0_u32
          children_count = node.children.try(&.size) || 0
          
          case type
          when NodeType::Null
            value_ref = 0
          when NodeType::Bool
            value_ref = node.value == true ? 1_u32 : 0_u32
          when NodeType::Int
            if node.value.is_a?(Int64)
              value_ref = node.value.as(Int64).to_u32
            elsif node.value.is_a?(Int32)
              value_ref = node.value.as(Int32).to_u32
            else
              value_ref = 0
            end
          when NodeType::Float
            value_ref = store_float(node.value)
          when NodeType::String
            value_ref = @string_table.get_id(node.value.to_s)
          when NodeType::Array, NodeType::Object
            if children_count > 0
              first_child = node.children.not_nil![0]
              value_ref = first_child.id
            else
              value_ref = 0
            end
          end
          
          record = CompactNodeRecord.new(
            type_flags,
            parent_id,
            key_id,
            value_ref.to_u32,
            children_count.to_u32
          )
          
          @records << record
        end
      end
      
      private def store_float(value) : UInt32
        offset = @value_pool.size.to_u32
        
        case value
        when Float64
          @value_pool.write_bytes(value, IO::ByteFormat::LittleEndian)
        when Int64
          @value_pool.write_bytes(value.to_f64, IO::ByteFormat::LittleEndian)
        when Int32
          @value_pool.write_bytes(value.to_f64, IO::ByteFormat::LittleEndian)
        when Float32
          @value_pool.write_bytes(value.to_f64, IO::ByteFormat::LittleEndian)
        else
          @value_pool.write_bytes(0_f64, IO::ByteFormat::LittleEndian)
        end
        
        offset
      end
      
      private def serialize : Bytes
        string_bytes = @string_table.to_bytes
        
        nrt_io = IO::Memory.new
        @records.each do |record|
          nrt_io.write(record.to_bytes)
        end
        nrt_bytes = nrt_io.to_slice
        
        value_pool_bytes = @value_pool.to_slice
        
        header_size = 32_u64
        content_size = header_size + string_bytes.size + nrt_bytes.size + value_pool_bytes.size
        footer_offset = content_size
        
        io = IO::Memory.new
        
        io.write(MAGIC.to_slice)
        io.write_bytes(VERSION, IO::ByteFormat::LittleEndian)
        io.write_bytes(@records.size.to_u64, IO::ByteFormat::LittleEndian)
        io.write_bytes(string_bytes.size.to_u64, IO::ByteFormat::LittleEndian)
        io.write_bytes(footer_offset.to_u64, IO::ByteFormat::LittleEndian)
        
        io.write(string_bytes)
        io.write(nrt_bytes)
        io.write(value_pool_bytes)
        
        checksum = calculate_checksum(io.to_slice)
        io.write_bytes(checksum, IO::ByteFormat::LittleEndian)
        padded_magic = MAGIC_FOOTER.ljust(16, '\0')
        io.write(padded_magic.to_slice)
        
        io.to_slice
      end
      
      private def calculate_checksum(data : Bytes) : UInt64
        hash = 14695981039346656037_u64
        data.each do |byte|
          hash ^= byte.to_u64
          hash = hash &* 1099511628211_u64
        end
        hash
      end
      
      def node_count : UInt64
        @records.size.to_u64
      end
      
      def string_count : UInt64
        @string_table.size.to_u64
      end
    end
  end
end
