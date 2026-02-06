# Ocelot Binary Format Specification

## Overview

The `.ocel` format is a binary, deterministic, index-friendly format for storing JSON data. It is designed for external indexing at billions of nodes.

## Layout

```
+-------------------+
| Header (32 bytes) |
+-------------------+
| String Table      |
+-------------------+
| Node Record Table|
+-------------------+
| Value Pool        |
+-------------------+
| Footer (16 bytes) |
+-------------------+
```

## Header (32 bytes)

| Offset | Size | Field                  | Description                                 |
|--------|------|------------------------|---------------------------------------------|
| 0      | 4    | Magic Number           | `0x4F 0x43 0x45 0x4C` ("OCEL")              |
| 4      | 4    | Version                | Format version (1)                          |
| 8      | 8    | Node Count             | Number of nodes in the Node Record Table    |
| 16     | 8    | String Table Size      | Size of the string table in bytes           |
| 24     | 8    | Footer Offset          | Offset to the footer from start of file     |

## String Table

The string table contains all unique strings used in the JSON document. Each string is stored as a length-prefixed UTF-8 string.

```
+-------------------+
| Length (varint)   | 1-10 bytes
+-------------------+
| UTF-8 Bytes       | N bytes
+-------------------+
```

Strings are deduplicated and sorted lexicographically for determinism.

## Node Record Table

The Node Record Table (NRT) is a flat array of fixed-size node records. Each record is 24 bytes.

| Offset | Size | Field      | Description                                   |
|--------|------|------------|-----------------------------------------------|
| 0      | 1    | Type       | Node type (see Node Types)                    |
| 1      | 1    | Flags      | Flags (e.g., has_parent, has_key)             |
| 2      | 2    | Reserved   | Reserved for future use                       |
| 4      | 4    | Parent ID  | Index of parent node (0 if root)              |
| 8      | 4    | Key ID     | Index into string table for key (0 if none)   |
| 12     | 4    | Value Ref  | Index into Value Pool or direct value         |
| 16     | 8    | Children   | Number of children (for arrays/objects)       |

### Node Types

| Value | Type     | Description                           |
|-------|----------|---------------------------------------|
| 0     | Null     | JSON null                            |
| 1     | Bool     | Boolean value                        |
| 2     | Number   | Numeric value                        |
| 3     | String   | String value                         |
| 4     | Array    | Array of nodes                       |
| 5     | Object   | Object with key-value pairs          |

## Value Pool

The Value Pool stores actual values that don't fit in the Node Record:

- **Numbers**: IEEE 754 double-precision floating-point (8 bytes).
- **Strings**: Index into string table (4 bytes).
- **Booleans**: Stored in Node Record flags.
- **Arrays**: Offset and count into Node Record Table (16 bytes: 8 offset, 8 count).
- **Objects**: Offset and count into Node Record Table (16 bytes: 8 offset, 8 count).

## Footer (16 bytes)

| Offset | Size | Field       | Description                                 |
|--------|------|-------------|---------------------------------------------|
| 0      | 8    | Checksum    | xxHash64 of header + string table + NRT + Value Pool |
| 8      | 8    | Magic Footer| `0x4C 0x45 0x43 0x4F 0x54 0x45 0x4C 0x43` ("OCELOTELC") |

## Key-Specific Lanes (Optional)

For very hot keys (e.g., `packageName`), external indexers can maintain key-specific lanes:

```
Lane for "packageName":
+-------------------+
| Node ID (varint)  | 1-10 bytes
+-------------------+
| String ID (varint)|
+-------------------+
```

This allows O(1) lookups for common keys during linear scans.

## Example Walkthrough

Given JSON:

```json
{
  "name": "git-cli",
  "version": "1.0.0"
}
```

Binary layout:

1. **Header**: `OCEL` + version + node count (3) + string table size + footer offset
2. **String Table**: `"git-cli"` + `"name"` + `"version"` + `"1.0.0"` (sorted)
3. **Node Record Table**:
   - Node 0: Root Object (parent=0, children=2)
   - Node 1: String "git-cli" (parent=0, key="name")
   - Node 2: String "1.0.0" (parent=0, key="version")
4. **Footer**: xxHash64 + `OCELOTELC`

## Determinism Guarantees

- String table is sorted lexicographically.
- Node Record Table is ordered by first occurrence.
- Children of arrays/objects are stored contiguously.
- No timestamps or random identifiers.

## Performance Characteristics

- **mmap-friendly**: Linear access patterns.
- **Zero-copy parsing**: Node records reference string table and value pool.
- **Cache-friendly**: Fixed-size records enable SIMD processing.
- **External indexing**: No need to decompile for linear scans.
