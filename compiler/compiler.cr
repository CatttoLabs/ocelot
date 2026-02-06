require "../format/compact_writer"

module Ocelot
  module Compiler
    class Result
      property input_size : UInt64
      property output_size : UInt64
      property node_count : UInt64
      property string_count : UInt64
      
      def initialize(@input_size, @output_size, @node_count, @string_count)
      end
      
      def reduction_percent : Float64
        if @input_size > 0
          (1.0 - @output_size.to_f64 / @input_size.to_f64) * 100.0
        else
          0.0
        end
      end
    end
    
    def self.compile(input_path : String, output_path : String) : Result
      input_file = File.read(input_path)
      input_size = input_file.bytesize.to_u64
      
      json = JSON.parse(input_file)
      ir = IR::FromJson.new.convert(json)
      
      # Use compact format v2
      writer = Format::CompactBinaryWriter.new
      binary = writer.write(ir)
      
      File.write(output_path, binary)
      output_size = File.size(output_path).to_u64
      
      Result.new(input_size, output_size, writer.node_count, writer.string_count)
    end
  end
end
