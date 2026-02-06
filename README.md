<div align=center>

<img width="1640" height="664" alt="New Project (2)" src="https://github.com/user-attachments/assets/b7f7d914-d50d-4b85-9246-47c7f41f6caa" />

# ocelot

</div>

**Ocelot** is a JSON compiler and decompiler designed for massive-scale datasets.

## Features

- **Compile**: Transform JSON into a binary, deterministic, index-friendly format (`.ocel`).
- **Decompile**: Recover the original JSON from `.ocel` files losslessly.
- **Find**: Extract JSON subtrees by structural JSON matching.
- **Deterministic**: Same input always produces the same `.ocel` binary.
- **Index-friendly**: Optimized for external indexing at billions of nodes.

## Installation

```bash
git clone https://github.com/catttolabs/ocelot.git
cd ocelot
shards install
crystal build --release -o bin/ocelot cli.cr
```

## Usage

### Compile JSON to .ocel

```bash
./bin/ocelot compile input.json -o output.ocel
```

### Decompile .ocel to JSON

```bash
./bin/ocelot decompile output.ocel -o input.json
```

### Find Subtrees

```bash
./bin/ocelot find output.ocel --query '{ "packageName": "git-cli" }' -o git-cli-package.json
```

## Binary Format

Ocelot uses a custom binary format optimized for external indexing:

- **String Table**: Interned, deduplicated strings.
- **Node Record Table**: Fixed-size node records.
- **Value Pool**: Numbers, string IDs, arrays, objects.
- **Footer**: Checksum for integrity.

See [FORMAT.md](FORMAT.md) for detailed specification.

## License

MIT
