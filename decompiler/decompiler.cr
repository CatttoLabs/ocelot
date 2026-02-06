require "../format/compact_reader"

module Ocelot
  module Decompiler
    def self.decompile(input_path : String, output_path : String)
      slice = File.read(input_path).to_slice
      reader = Format::CompactBinaryReader.new(slice)
      ast = reader.read
      
      json = IR::ToJson.new.convert(ast)
      File.write(output_path, json)
    end
  end
end
