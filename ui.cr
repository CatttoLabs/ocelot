module Ocelot
  module UI
    # ANSI color codes
    RESET   = "\e[0m"
    BOLD    = "\e[1m"
    DIM     = "\e[2m"
    
    # Cat/Ocelot themed colors
    ORANGE  = "\e[38;5;208m"   # Ocelot orange/gold
    SPOT    = "\e[38;5;130m"   # Dark spots
    CREAM   = "\e[38;5;230m"   # Light fur
    BLACK   = "\e[38;5;232m"   # Dark patterns
    GREEN   = "\e[38;5;28m"    # Jungle green (eyes)
    
    # Semantic colors
    SUCCESS = "\e[38;5;82m"    # Bright green
    ERROR   = "\e[38;5;196m"   # Red
    WARN    = "\e[38;5;220m"   # Yellow/gold
    INFO    = "\e[38;5;39m"    # Blue
    
    # Output helpers
    def self.success(msg : String)
      puts "#{SUCCESS}[OK]#{RESET} #{msg}"
    end
    
    def self.error(msg : String)
      puts "#{ERROR}[XX]#{RESET} #{msg}"
    end
    
    def self.warn(msg : String)
      puts "#{WARN}[!!]#{RESET} #{msg}"
    end
    
    def self.info(msg : String)
      puts "#{INFO}[..]#{RESET} #{msg}"
    end
    
    def self.working(msg : String)
      print "#{ORANGE}[~~]#{RESET} #{msg}"
      STDOUT.flush
    end
    
    def self.done
      puts " #{SUCCESS}done#{RESET}"
    end
    
    def self.header(text : String)
      puts "\n#{BOLD}#{ORANGE}>> #{text}#{RESET}"
    end
    
    def self.stat(label : String, value : String)
      puts "  #{DIM}#{label}:#{RESET} #{value}"
    end
    
    def self.stat_number(label : String, value : Int64 | Int32 | UInt64 | UInt32)
      puts "  #{DIM}#{label}:#{RESET} #{BOLD}#{value}#{RESET}"
    end
    
    def self.stat_bytes(label : String, bytes : UInt64)
      size = human_readable_size(bytes)
      puts "  #{DIM}#{label}:#{RESET} #{BOLD}#{size}#{RESET}"
    end
    
    def self.stat_percent(label : String, value : Float64)
      color = value > 0 ? SUCCESS : ERROR
      sign = value > 0 ? "+" : ""
      puts "  #{DIM}#{label}:#{RESET} #{color}#{sign}#{value.round(2)}%#{RESET}"
    end
    
    def self.human_readable_size(bytes : UInt64) : String
      if bytes < 1024
        "#{bytes} B"
      elsif bytes < 1024 * 1024
        "#{(bytes / 1024.0).round(2)} KB"
      elsif bytes < 1024 * 1024 * 1024
        "#{(bytes / (1024.0 * 1024.0)).round(2)} MB"
      else
        "#{(bytes / (1024.0 * 1024.0 * 1024.0)).round(2)} GB"
      end
    end
    
    def self.print_banner
      puts BANNER
      puts
    end
    
    def self.show_help
      print_banner
      puts "#{BOLD}Usage:#{RESET} ocelot <command> [options]"
      puts
      puts "#{BOLD}Commands:#{RESET}"
      puts "  #{ORANGE}compile#{RESET}     <input.json> -o <output.ocel>"
      puts "  #{ORANGE}decompile#{RESET}   <input.ocel> -o <output.json>"
      puts "  #{ORANGE}find#{RESET}        <input.ocel> --query <json> -o <output.json>"
      puts "  #{ORANGE}info#{RESET}        <input.ocel>              Show file statistics"
      puts "  #{ORANGE}version#{RESET}                              Show version"
      puts "  #{ORANGE}help#{RESET}                                 Show this help"
      puts
      puts "#{BOLD}Options:#{RESET}"
      puts "  -o, --output FILE    Output file path"
      puts "  -q, --query JSON     Query for find command"
      puts "  -v, --verbose        Verbose output"
      puts "  -h, --help           Show help"
      puts
      puts "#{DIM}Examples:#{RESET}"
      puts "  ocelot compile package.json -o package.ocel"
      puts "  ocelot decompile package.ocel -o package.json"
      puts "  ocelot find packages.ocel --query '{\"name\":\"express\"}'"
    end
  end
end
