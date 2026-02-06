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

```bash
curl -fsSL https://raw.githubusercontent.com/CatttoLabs/ocelot/refs/heads/main/install.sh | bash # YOLO
```

## Usage

1. Compile JSON to .ocel

```bash
ocelot compile input.json -o output.ocel
```

2. Decompile .ocel to JSON

```bash
ocelot decompile output.ocel -o input.json
```

3. Find Subtrees

```bash
ocelot find output.ocel --query '{ "packageName": "git-cli" }' -o git-cli-package.json
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
