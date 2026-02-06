require "json"
require "option_parser"

require "./ir/*"
require "./format/*"
require "./compiler/*"
require "./decompiler/*"
require "./find/*"
require "./ui"
require "./banner"

module Ocelot
  VERSION = "0.1.0"

  def self.run
    subcommand = ARGV[0]?
    
    case subcommand
    when "compile"
      compile_cmd
    when "decompile"
      decompile_cmd
    when "find"
      find_cmd
    when "info"
      info_cmd
    when "version", "--version", "-v"
      UI.print_banner
      puts "ocelot v#{VERSION}"
    when "help", "--help", "-h"
      UI.show_help
    when nil
      UI.show_help
    else
      UI.error "Unknown command: #{subcommand}"
      puts
      UI.show_help
      exit 1
    end
  end

  private def self.compile_cmd
    input_path = ""
    output_path = ""
    verbose = false
    
    parser = OptionParser.new
    parser.banner = "Usage: ocelot compile [options] <input.json>"
    parser.on("-o OUTPUT", "--output=OUTPUT", "Output file path") { |v| output_path = v }
    parser.on("-v", "--verbose", "Verbose output") { verbose = true }
    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end
    parser.invalid_option { }
    
    # Parse options
    begin
      parser.parse(ARGV[1..])
    rescue
    end
    
    # Get input file from remaining args (first positional arg after options)
    input_arg = ARGV[1..].find { |arg| !arg.starts_with?("-") }
    input_path = input_arg if input_arg
    
    if input_path.empty?
      UI.error "Missing input file"
      puts
      puts parser
      exit 1
    end
    
    # Generate output path if not provided
    if output_path.empty?
      # Default: input filename with .ocel extension
      output_path = input_path + ".ocel"
    else
      # Always append .ocel to the specified output name
      output_path = output_path + ".ocel"
    end
    
    unless File.exists?(input_path)
      UI.error "File not found: #{input_path}"
      exit 1
    end
    
    UI.header "Compiling"
    UI.info "Input:  #{input_path}"
    UI.info "Output: #{output_path}"
    
    result = Compiler.compile(input_path, output_path)
    
    UI.success "Compilation complete"
    puts
    UI.stat_bytes "Input size", result.input_size
    UI.stat_bytes "Output size", result.output_size
    UI.stat_number "Nodes", result.node_count
    UI.stat_number "Strings", result.string_count
    UI.stat_percent "Size change", result.reduction_percent
    
    if result.reduction_percent > 0
      UI.success "Compressed by #{result.reduction_percent.round(1)}%"
    elsif result.reduction_percent < 0
      UI.warn "Size increased by #{result.reduction_percent.abs.round(1)}% (try with larger datasets)"
    end
  end

  private def self.decompile_cmd
    input_path = ""
    output_path = ""
    
    parser = OptionParser.new
    parser.banner = "Usage: ocelot decompile [options] <input.ocel>"
    parser.on("-o OUTPUT", "--output=OUTPUT", "Output file path") { |v| output_path = v }
    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end
    parser.invalid_option { }
    
    begin
      parser.parse(ARGV[1..])
    rescue
    end
    
    # Get input file from remaining args (first positional arg after options)
    input_arg = ARGV[1..].find { |arg| !arg.starts_with?("-") }
    input_path = input_arg if input_arg
    
    if input_path.empty?
      UI.error "Missing input file"
      puts
      puts parser
      exit 1
    end
    
    # Generate output path if not provided
    if output_path.empty?
      # Default: input filename with .json extension
      # Remove .ocel if present, then add .json
      if input_path.ends_with?(".ocel")
        output_path = input_path.rchop(".ocel") + ".json"
      else
        output_path = input_path + ".json"
      end
    end
    
    unless File.exists?(input_path)
      UI.error "File not found: #{input_path}"
      exit 1
    end
    
    UI.header "Decompiling"
    UI.info "Input:  #{input_path}"
    UI.info "Output: #{output_path}"
    
    Decompiler.decompile(input_path, output_path)
    
    output_size = File.size(output_path)
    UI.success "Decompilation complete"
    UI.stat_bytes "Output size", output_size.to_u64
  end

  private def self.find_cmd
    input_path = ""
    output_path = ""
    query = ""
    
    parser = OptionParser.new
    parser.banner = "Usage: ocelot find [options] <input.ocel>"
    parser.on("-o OUTPUT", "--output=OUTPUT", "Output file path") { |v| output_path = v }
    parser.on("-q QUERY", "--query=QUERY", "JSON query pattern") { |v| query = v }
    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end
    parser.invalid_option { }
    
    begin
      parser.parse(ARGV[1..])
    rescue
    end
    
    # Get input file from remaining args (first positional arg after options)
    input_arg = ARGV[1..].find { |arg| !arg.starts_with?("-") }
    input_path = input_arg if input_arg
    
    if input_path.empty? || query.empty? || output_path.empty?
      UI.error "Missing required arguments"
      puts
      puts parser
      exit 1
    end
    
    unless File.exists?(input_path)
      UI.error "File not found: #{input_path}"
      exit 1
    end
    
    begin
      query_json = JSON.parse(query)
    rescue ex
      UI.error "Invalid JSON query: #{ex.message}"
      exit 1
    end
    
    UI.header "Searching"
    UI.info "Input:  #{input_path}"
    UI.info "Query:  #{query}"
    UI.info "Output: #{output_path}"
    
    Find.find(input_path, query_json, output_path)
    
    UI.success "Search complete"
  end
  
  private def self.info_cmd
    input_path = ""
    
    parser = OptionParser.new
    parser.banner = "Usage: ocelot info [options] <input.ocel>"
    parser.on("-h", "--help", "Show help") do
      puts parser
      exit
    end
    parser.invalid_option { }
    
    begin
      parser.parse(ARGV[1..])
    rescue
    end
    
    # Get input file from remaining args (first positional arg after options)
    input_arg = ARGV[1..].find { |arg| !arg.starts_with?("-") }
    input_path = input_arg if input_arg
    
    if input_path.empty?
      UI.error "Missing input file"
      puts
      puts parser
      exit 1
    end
    
    unless File.exists?(input_path)
      UI.error "File not found: #{input_path}"
      exit 1
    end
    
    UI.header "File Information"
    UI.info input_path
    
    begin
      reader = Format::CompactBinaryReader.new(File.read(input_path).to_slice)
      reader.read  # Parse to populate internal state
      
      puts
      UI.stat_bytes "File size", File.size(input_path).to_u64
      UI.stat_number "Nodes", reader.node_count
      UI.stat_number "Strings", reader.@string_table.size
    rescue ex
      UI.error "Failed to read file: #{ex.message}"
      exit 1
    end
  end
end

Ocelot.run
