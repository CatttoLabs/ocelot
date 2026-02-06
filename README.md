<div align=center>

<img width="1640" height="664" alt="New Project (2)" src="https://github.com/user-attachments/assets/b7f7d914-d50d-4b85-9246-47c7f41f6caa" />

# ocelot

![GitHub release](https://img.shields.io/github/v/release/catttolabs/ocelot?style=for-the-badge)
![GitHub stars](https://img.shields.io/github/stars/catttolabs/ocelot?style=for-the-badge)
![GitHub license](https://img.shields.io/github/license/catttolabs/ocelot?style=for-the-badge)
![Release workflow](https://img.shields.io/github/actions/workflow/status/catttolabs/ocelot/release.yml?style=for-the-badge)
![Last commit](https://img.shields.io/github/last-commit/catttolabs/ocelot?style=for-the-badge)


</div>

**Ocelot** is a JSON compiler and decompiler designed for massive-scale datasets.

## Features

- **Compile**: Transform JSON into a binary, deterministic, index-friendly format (`.ocel`).
- **Decompile**: Recover the original JSON from `.ocel` files losslessly.
- **Find**: Extract JSON subtrees by structural JSON matching.
- **Deterministic**: Same input always produces the same `.ocel` binary.
- **Index-friendly**: Optimized for external indexing at billions of nodes.

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/CatttoLabs/ocelot/refs/heads/main/install.sh | bash
```

### Build from Source

```bash
# Install Crystal (https://crystal-lang.org/install/)
git clone https://github.com/CatttoLabs/ocelot.git
cd ocelot
shards install
make build
./bin/ocelot --version
```

### System Requirements

- **Crystal**: 1.18.2 or later
- **Memory**: 512MB minimum (for large datasets)
- **OS**: Linux, macOS, or Windows (via WSL)

## Usage

### Basic Operations

1. **Compile JSON to .ocel**

```bash
ocelot compile input.json -o output.ocel
```

2. **Decompile .ocel to JSON**

```bash
ocelot decompile output.ocel -o input.json
```

3. **Find Subtrees**

```bash
ocelot find output.ocel --query '{ "packageName": "git-cli" }' -o git-cli-package.json
```

4. **Get File Information**

```bash
ocelot info dataset.ocel
```

### Advanced Options

```bash
# Compile with verbose output
ocelot compile large-dataset.json -o dataset.ocel --verbose

# Find with multiple output files
ocelot find dataset.ocel --query '{ "type": "user" }' -o users/ --split

# Stream compilation for very large files
ocelot compile huge.json -o huge.ocel --stream

# Automatic output naming
ocelot compile input.json  # Creates input.ocel
ocelot decompile input.ocel  # Creates input.json
```

### Command Reference

All commands support `--help` for detailed options:

```bash
ocelot --help          # General help
ocelot compile --help  # Compile options
ocelot decompile --help  # Decompile options
ocelot find --help     # Search options
ocelot info --help     # File information options
```

### CLI Features

- **Automatic Output Naming**: Omit `-o` flag for automatic file naming
- **Verbose Mode**: Use `--verbose` for detailed statistics and progress
- **Themed Output**: Color-coded output with ocelot theme (orange/spot/cream/black)
- **Statistics Reporting**: Compression ratios, node counts, and processing times
- **Error Handling**: Comprehensive validation and user-friendly error messages

## Architecture

Ocelot follows a clean pipeline architecture:

```
JSON Input → IR::FromJson → IR AST → CompactBinaryWriter → .ocel Binary
.ocel Binary → CompactBinaryReader → IR AST → IR::ToJson → JSON Output
```

### Core Components

- **IR (Intermediate Representation)**: AST-like structure for JSON manipulation with `Node` class and `NodeType` enum
- **Compact Format**: Custom binary format with string deduplication and fixed-size records
- **CLI Interface**: Command-line tools for compilation, decompilation, and search
- **UI System**: Themed color output and progress indicators
- **Binary Format**: Optimized `.ocel` format with magic numbers and checksums

### Data Flow

1. **Compilation**: JSON → IR AST → Compact Binary → .ocel file
2. **Decompilation**: .ocel file → Compact Binary → IR AST → JSON
3. **Search**: .ocel file → Compact Binary → IR AST → Pattern Matching → Results

### Node Types

The IR supports all JSON node types:
- **Null**: `null` values
- **Bool**: `true`/`false` values  
- **Number**: Integer and floating-point numbers
- **String**: Text values with deduplication
- **Array**: Ordered collections with variable length
- **Object**: Key-value pairs with string keys

## Binary Format

Ocelot uses a custom binary format (`.ocel`) optimized for external indexing:

### Format Structure

- **Header (32 bytes)**: Magic number "OCE2", version, node count, string table size, footer offset
- **String Table**: Interned, deduplicated strings with prefix compression for memory efficiency
- **Node Record Table**: Fixed-size 16-byte node records for O(1) random access
- **Value Pool**: Numbers, string IDs, array references, and object references
- **Footer (16 bytes)**: Checksum and magic footer "OCELOTEND" for integrity verification

### Key Features

- **Magic Numbers**: "OCE2" header and "OCELOTEND" footer for format identification
- **Version 2 Format**: Current implementation uses CompactBinaryWriter v2
- **mmap-friendly**: Linear access patterns optimized for memory mapping
- **Zero-copy Parsing**: Node records reference string table directly
- **Prefix Compression**: String table uses prefix compression for efficiency

### Performance Characteristics

- **Fixed-size Records**: 16-byte node records enable O(1) random access
- **String Deduplication**: All strings are interned and sorted lexicographically
- **Deterministic Output**: Same input always produces identical binary
- **Index-Friendly**: Optimized for external indexing systems

See [FORMAT.md](FORMAT.md) for detailed specification.

## Performance

### Benchmarks

- **Memory**: Up to 90% reduction vs raw JSON through string deduplication
- **Speed**: Sub-second compilation for GB-scale datasets
- **Indexing**: O(1) node access for external indexing systems
- **Scalability**: Tested with billions of JSON nodes

### Optimization Techniques

- **String Interning**: All strings are deduplicated and stored in a sorted string table
- **Fixed-size Records**: 16-byte node records enable constant-time random access
- **Prefix Compression**: String table uses prefix compression for additional savings
- **Linear Access**: Optimized for memory mapping and sequential I/O
- **Zero-copy Operations**: Node records reference string table without copying

### Use Case Performance

Ocelot is specifically optimized for:
- **Package Manager Registries**: npm, PyPI, Cargo registry scale datasets
- **Large-scale Analytics**: Billions of JSON nodes with efficient querying
- **Storage Optimization**: Significant reduction in storage requirements
- **External Indexing**: Fast node access for search and indexing systems

## Development

### Local Development Setup

```bash
git clone https://github.com/CatttoLabs/ocelot.git
cd ocelot
shards install
make build
./bin/ocelot --help
```

### Testing

```bash
make test          # Run all tests
make spec          # Run Crystal specs
make lint          # Code quality checks
```

### Build Targets

```bash
make build         # Build for current platform
make release       # Build release binaries for all platforms
make clean         # Clean build artifacts
make install       # Install to system PATH
make test          # Run all tests
make spec          # Run Crystal specs
make lint          # Code quality checks
```

### Release Process

The project uses automated GitHub Actions for releases:
- **Linux x86_64**: Optimized builds for Linux servers
- **macOS x86_64**: Intel-based Mac support
- **macOS arm64**: Apple Silicon (M1/M2) support
- **Installer Script**: Cross-platform installation with automatic detection

### Project Structure

```
src/
├── cli.cr              # Main CLI entry point and command routing
├── banner.cr           # ASCII art banner for CLI branding
├── ui.cr               # Themed color output and progress indicators
├── ir/                  # Intermediate Representation
│   ├── ir.cr           # Core IR definitions with Node class and NodeType enum
│   ├── from_json.cr    # JSON → IR conversion
│   └── to_json.cr      # IR → JSON conversion with proper escaping
├── format/              # Binary format implementation
│   ├── compact.cr      # Core format structures and node records
│   ├── compact_writer.cr # Binary writer with v2 format
│   └── compact_reader.cr # Binary reader and format parsing
├── compiler/            # Compilation logic
│   └── compiler.cr     # JSON → .ocel compilation with statistics
├── decompiler/          # Decompilation logic
│   └── decompiler.cr   # .ocel → JSON decompilation
└── find/               # Search functionality
    └── find.cr         # Structural JSON matching and subtree extraction
```

### Key Files

- **`shard.yml`**: Crystal project configuration and dependencies
- **`Makefile`**: Comprehensive build targets for multiple platforms
- **`install.sh`**: Sophisticated installer with OS/architecture detection
- **`.github/workflows/release.yml`**: Automated builds for multiple platforms

## Contributing

We welcome contributions! Please see our guidelines:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### Code Style

- Follow Crystal style guidelines
- Use meaningful variable names
- Add inline documentation for public APIs
- Keep functions focused and small

## Troubleshooting

### Common Issues

**"Out of memory" during compilation**
- Use `--stream` flag for large files
- Increase available memory
- Split input into smaller chunks

**"Binary verification failed"**
- Check file integrity with `ocelot info` command
- Ensure file wasn't corrupted during transfer
- Recompile from original JSON

**"Query returns no results"**
- Verify query syntax matches JSON structure exactly
- Use `ocelot find --help` for query options
- Test with simpler queries first
- Check that the JSON structure exists in the compiled file

**"File not found" errors**
- Ensure input files exist and are readable
- Check file permissions
- Use absolute paths if relative paths fail

**"Invalid JSON" errors**
- Validate JSON syntax before compilation
- Check for trailing commas or missing quotes
- Use a JSON linter to identify syntax issues

### Getting Help

- **Issues**: [GitHub Issues](https://github.com/CatttoLabs/ocelot/issues) for bug reports and feature requests
- **Discussions**: [GitHub Discussions](https://github.com/CatttoLabs/ocelot/discussions) for questions and community support
- **Documentation**: [FORMAT.md](FORMAT.md) for binary format details
- **CLI Help**: Use `ocelot --help` and `ocelot <command> --help` for command-specific assistance

## Examples

### Package Registry Use Case

```bash
# Compile a large npm registry dataset
ocelot compile npm-registry.json -o npm-registry.ocel

# Find all packages with "express" in the name
ocelot find npm-registry.ocel --query '{"name":"express"}' -o express-packages.json

# Get file information
ocelot info npm-registry.ocel
# Output: Nodes: 1,234,567 | Size: 45.2MB | Compression: 87%
```

### Data Analysis Workflow

```bash
# Compile multiple JSON files
for file in data/*.json; do
    ocelot compile "$file" --verbose
done

# Search across compiled files
ocelot find data/*.ocel --query '{"type":"user","active":true}' -o active-users.json

# Decompile specific results
ocelot decompile active-users.json -o analysis-ready.json
```

## Target Applications

Ocelot is designed for specific use cases:

- **Package Manager Registries**: npm, PyPI, Cargo registry scale datasets
- **Large-scale Analytics**: Billions of JSON nodes with efficient querying
- **Storage Optimization**: Significant reduction in storage requirements
- **External Indexing**: Fast node access for search and indexing systems
- **Data Pipeline Processing**: Efficient JSON transformation and analysis

## License

MIT
