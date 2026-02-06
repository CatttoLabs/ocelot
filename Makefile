# Makefile for Ocelot

# Compiler and flags
CRYSTAL ?= crystal
CRYSTAL_FLAGS ?= --release

# Binary names and paths
BINARY ?= ocelot
DEBUG_BINARY ?= ocelot-debug
LINUX_BINARY ?= bin/ocelot-linux-x86_64
MACOS_X86_64_BINARY ?= bin/ocelot-macos-x86_64
MACOS_AARCH64_BINARY ?= bin/ocelot-macos-aarch64

# Source files
MAIN_SOURCE ?= cli.cr

# Build directories
build_dir := bin

# Default target
default: build

# Build targets
build: $(build_dir) $(BINARY)

$(build_dir):
	mkdir -p $(build_dir)

$(BINARY): $(MAIN_SOURCE)
	$(CRYSTAL) build $(CRYSTAL_FLAGS) -o $(BINARY) $(MAIN_SOURCE)

debug: $(build_dir) $(DEBUG_BINARY)

$(DEBUG_BINARY): $(MAIN_SOURCE)
	$(CRYSTAL) build -o $(DEBUG_BINARY) $(MAIN_SOURCE)

linux: $(build_dir) $(LINUX_BINARY)

$(LINUX_BINARY): $(MAIN_SOURCE)
	$(CRYSTAL) build $(CRYSTAL_FLAGS) -o $(LINUX_BINARY) $(MAIN_SOURCE)

macos-x86_64: $(build_dir) $(MACOS_X86_64_BINARY)

$(MACOS_X86_64_BINARY): $(MAIN_SOURCE)
	$(CRYSTAL) build $(CRYSTAL_FLAGS) -o $(MACOS_X86_64_BINARY) $(MAIN_SOURCE)

macos-aarch64: $(build_dir) $(MACOS_AARCH64_BINARY)

$(MACOS_AARCH64_BINARY): $(MAIN_SOURCE)
	$(CRYSTAL) build $(CRYSTAL_FLAGS) -o $(MACOS_AARCH64_BINARY) $(MAIN_SOURCE)

# Clean targets
clean:
	rm -f $(BINARY) $(DEBUG_BINARY) $(LINUX_BINARY) $(MACOS_X86_64_BINARY) $(MACOS_AARCH64_BINARY)
	rm -rf $(build_dir)

clean-all: clean
	rm -f *.dwarf

# Install target
install: $(BINARY)
	install -m 755 $(BINARY) /usr/local/bin/

# Test target
test:
	$(CRYSTAL) spec

# Run target
run: $(BINARY)
	./$(BINARY)

# Help target
help:
	@echo "Available targets:"
	@echo "  build          - Build release binary"
	@echo "  debug          - Build debug binary"
	@echo "  linux          - Build Linux x86_64 binary"
	@echo "  macos-x86_64   - Build macOS x86_64 binary"
	@echo "  macos-aarch64  - Build macOS arm64 binary"
	@echo "  clean          - Remove all built binaries"
	@echo "  clean-all      - Remove all built binaries and debug symbols"
	@echo "  install        - Install binary to /usr/local/bin"
	@echo "  test           - Run tests"
	@echo "  run            - Run the binary"
	@echo "  help           - Show this help message"

.PHONY: default build clean clean-all install test run help linux macos-x86_64 macos-aarch64 debug