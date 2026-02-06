module Ocelot
  module Format
    enum NodeType : UInt8
      Null     = 0
      Bool     = 1
      Int      = 2
      Float    = 3
      String   = 4
      Array    = 5
      Object   = 6
    end
    
    struct CompactNodeRecord
      property type_flags : UInt8
      property parent_id : UInt32
      property key_id : UInt32
      property value_ref : UInt32
      property children_count : UInt32
      
      def initialize(@type_flags = 0_u8, @parent_id = 0_u32, @key_id = 0_u32, @value_ref = 0_u32, @children_count = 0_u32)
      end
      
      def type : NodeType
        NodeType.new((@type_flags >> 4) & 0x0F)
      end
      
      def has_parent? : Bool
        (@type_flags & 0x01) != 0
      end
      
      def has_key? : Bool
        (@type_flags & 0x02) != 0
      end
      
      def is_container? : Bool
        (@type_flags & 0x04) != 0
      end
      
      def to_bytes : Bytes
        bytes = Bytes.new(16)
        bytes[0] = @type_flags
        bytes[1] = (@parent_id & 0xFF).to_u8
        bytes[2] = ((@parent_id >> 8) & 0xFF).to_u8
        bytes[3] = ((@parent_id >> 16) & 0xFF).to_u8
        bytes[4] = ((@parent_id >> 24) & 0xFF).to_u8
        bytes[5] = (@key_id & 0xFF).to_u8
        bytes[6] = ((@key_id >> 8) & 0xFF).to_u8
        bytes[7] = ((@key_id >> 16) & 0xFF).to_u8
        bytes[8] = ((@key_id >> 24) & 0xFF).to_u8
        bytes[9] = (@value_ref & 0xFF).to_u8
        bytes[10] = ((@value_ref >> 8) & 0xFF).to_u8
        bytes[11] = ((@value_ref >> 16) & 0xFF).to_u8
        bytes[12] = ((@value_ref >> 24) & 0xFF).to_u8
        bytes[13] = (@children_count & 0xFF).to_u8
        bytes[14] = ((@children_count >> 8) & 0xFF).to_u8
        bytes[15] = ((@children_count >> 16) & 0xFF).to_u8
        bytes
      end
      
      def self.from_bytes(bytes : Bytes) : CompactNodeRecord
        type_flags = bytes[0]
        parent_id = bytes[1].to_u32 | (bytes[2].to_u32 << 8) | (bytes[3].to_u32 << 16) | (bytes[4].to_u32 << 24)
        key_id = bytes[5].to_u32 | (bytes[6].to_u32 << 8) | (bytes[7].to_u32 << 16) | (bytes[8].to_u32 << 24)
        value_ref = bytes[9].to_u32 | (bytes[10].to_u32 << 8) | (bytes[11].to_u32 << 16) | (bytes[12].to_u32 << 24)
        children_count = bytes[13].to_u32 | (bytes[14].to_u32 << 8) | (bytes[15].to_u32 << 16)
        new(type_flags, parent_id, key_id, value_ref, children_count)
      end
    end
    
    # Simple string table using array indexed by ID for deserialization
    # and hash table for deduplication during serialization
    class CompactStringTable
      # For serialization: hash table
      @index : Hash(String, UInt32)
      @next_id : UInt32
      
      # For both: array indexed by ID
      @strings_by_id : Array(String)
      
      def initialize
        @index = {} of String => UInt32
        @strings_by_id = [] of String
        @next_id = 0_u32
      end
      
      def get_id(str : String) : UInt32
        # Check if exists
        if id = @index[str]?
          return id
        end
        
        # Add new
        id = @next_id
        @strings_by_id << str
        @index[str] = id
        @next_id += 1
        
        id
      end
      
      def get_string(id : UInt32) : String
        return "" if id >= @strings_by_id.size
        @strings_by_id[id]
      end
      
      def size : UInt32
        @strings_by_id.size.to_u32
      end
      
      def to_bytes : Bytes
        io = IO::Memory.new
        io.write_bytes(@strings_by_id.size.to_u32, IO::ByteFormat::LittleEndian)
        
        # Sort strings by content for prefix compression
        sorted = [] of Tuple(UInt32, String)
        @strings_by_id.each_with_index do |str, id|
          sorted << {id.to_u32, str}
        end
        sorted.sort_by! { |id, str| str }
        
        # Write with prefix compression
        last_str = ""
        sorted.each do |id, str|
          # Find common prefix length
          common = 0
          max_common = {last_str.size, str.size}.min
          while common < max_common && last_str[common] == str[common]
            common += 1
          end
          
          suffix = str[common..-1]
          
          io.write_bytes(id, IO::ByteFormat::LittleEndian)
          io.write_bytes(common.to_u16, IO::ByteFormat::LittleEndian)
          io.write_bytes(suffix.bytesize.to_u16, IO::ByteFormat::LittleEndian)
          io.write(suffix.to_slice)
          
          last_str = str
        end
        
        io.to_slice
      end
      
      def self.from_bytes(slice : Bytes) : CompactStringTable
        return CompactStringTable.new if slice.size < 4
        
        io = IO::Memory.new(slice)
        count = io.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
        
        table = CompactStringTable.new
        last_str = ""
        
        count.times do
          break if io.pos + 8 > io.size
          
          id = io.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
          prefix_len = io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
          suffix_len = io.read_bytes(UInt16, IO::ByteFormat::LittleEndian)
          
          break if io.pos + suffix_len > io.size
          
          suffix_bytes = Bytes.new(suffix_len)
          io.read_fully(suffix_bytes)
          suffix = String.new(suffix_bytes)
          
          # Reconstruct string
          str = last_str[0, prefix_len] + suffix
          
          # Ensure array is large enough
          while table.@strings_by_id.size <= id
            table.@strings_by_id << ""
          end
          table.@strings_by_id[id] = str
          table.@index[str] = id
          
          last_str = str
        end
        
        table
      end
    end
  end
end
