require "./format/compact"
require "./format/compact_writer"
require "./format/compact_reader"

module Ocelot
  module Format
    # Universal binary format interface
    # Auto-detects format version and provides unified access
    
    def self.write(ast : IR::AST, version : Int32 = 2) : Bytes
      case version
      when 2
        CompactBinaryWriter.new.write(ast)
      else
        raise "Unsupported format version: #{version}"
      end
    end
    
    def self.read(slice : Bytes) : IR::AST
      # Detect version from magic
      if slice.size < 4
        raise "File too small"
      end
      
      magic = String.new(slice[0, 4])
      
      case magic
      when "OCE2"
        CompactBinaryReader.new(slice).read
      when "OCEL"
        # Version 1 - would need to implement legacy reader
        raise "Legacy format v1 no longer supported"
      else
        raise "Unknown format: #{magic}"
      end
    end
    
    # Get file info without full parse
    def self.info(slice : Bytes) : FileInfo
      if slice.size < 32
        raise "File too small"
      end
      
      magic = String.new(slice[0, 4])
      version = IO::Memory.new(slice[4, 4]).read_bytes(UInt32, IO::ByteFormat::LittleEndian)
      node_count = IO::Memory.new(slice[8, 8]).read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      string_table_size = IO::Memory.new(slice[16, 8]).read_bytes(UInt64, IO::ByteFormat::LittleEndian)
      
      FileInfo.new(
        magic: magic,
        version: version.to_i,
        node_count: node_count,
        string_table_size: string_table_size,
        file_size: slice.size.to_u64
      )
    end
    
    struct FileInfo
      property magic : String
      property version : Int32
      property node_count : UInt64
      property string_table_size : UInt64
      property file_size : UInt64
      
      def initialize(@magic, @version, @node_count, @string_table_size, @file_size)
      end
    end
  end
end
