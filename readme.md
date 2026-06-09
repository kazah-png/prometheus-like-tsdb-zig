<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,50:1a0d00,100:291500&height=130&section=header&text=prometheus-like-tsdb&fontSize=36&fontColor=e6edf3&animation=fadeIn&fontAlignY=55" />
</div>

<div align="center">

[![Zig](https://img.shields.io/badge/Zig-0.13%2B-F7A41D?style=flat&logo=zig&logoColor=white)](https://ziglang.org)
[![License](https://img.shields.io/badge/License-MIT-3fb950?style=flat)](LICENSE)
[![Storage](https://img.shields.io/badge/Storage-Gorilla%20%2B%20WAL-F7A41D?style=flat)]()

**Time series database written from scratch in Zig.**  
Gorilla XOR compression · Write-ahead log · Inverted label index · HTTP ingest & query API · No dependencies

</div>

---

## Overview

A minimal time series database inspired by Prometheus, implemented entirely in Zig with no external dependencies. It ingests metrics over HTTP in Prometheus text exposition format, compresses float samples using **Gorilla XOR encoding**, persists writes to a **write-ahead log** for crash recovery, and provides fast label filtering through an **inverted index**.

Zig gives direct control over memory layout and allocation — no garbage collector, no runtime, no hidden copies. Every data structure is sized and aligned explicitly.

---

## Architecture

```
HTTP /api/v1/write
        │
        ▼
    WAL (disk)          ← written first, before anything else
        │
        ▼
  InvertedIndex         ← label set → series ID mapping
        │
        ▼
  Series (memory)       ← active chunk per series
        │
        ▼
  Block (Gorilla)       ← sealed chunks compressed and flushed to disk (mmap)
        │
        ▼
HTTP /api/v1/query      ← reads from memory + disk blocks, applies label matchers
```

**Write path:** every sample is appended to the WAL first, then added to the in-memory series chunk. If the process crashes, the WAL is replayed on startup to recover the in-flight window.

**Read path:** label matchers resolve a set of series IDs via the inverted index. Each matched series streams samples from its active memory chunk and any sealed on-disk blocks that overlap the requested time range.

---

## Features

| Feature | Status |
|---|---|
| HTTP push ingest (Prometheus text format) | ✅ |
| Write-ahead log for crash recovery | ✅ |
| Gorilla XOR compression (float64 samples) | ✅ |
| DFCM compression (integer timestamps) | ✅ |
| Inverted label index | ✅ |
| Label matcher queries `{k="v", k2=~"re"}` | ✅ |
| Aggregations: `sum`, `avg`, `max`, `min` | ✅ |
| Memory-mapped block files | ✅ |
| Retention / compaction | planned |
| Remote read/write protocol | planned |

---

## Quick Start

```bash
# Requires Zig 0.13+
zig build

zig build run -- --listen 0.0.0.0:9090 --data-dir ./data
```

---

## API

### Write metrics

Prometheus text exposition format over HTTP POST:

```bash
curl -X POST http://localhost:9090/api/v1/write \
  -d 'cpu_usage{instance="srv1",core="0"} 42.5 1700000000
cpu_usage{instance="srv1",core="1"} 38.1 1700000000
mem_used_bytes{instance="srv1"} 2147483648 1700000000'
```

Each line: `metric_name{label="value",...} float_value unix_timestamp_seconds`

### Query

```bash
# Instant query — latest value matching the selector
curl 'http://localhost:9090/api/v1/query?query=cpu_usage{instance="srv1"}'

# Range query
curl 'http://localhost:9090/api/v1/query_range?query=cpu_usage{instance="srv1"}&start=1700000000&end=1700003600&step=60'

# Aggregation
curl 'http://localhost:9090/api/v1/query?query=avg(cpu_usage{instance="srv1"})'
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {"__name__": "cpu_usage", "instance": "srv1", "core": "0"},
        "value":  [1700000000, "42.5"]
      }
    ]
  }
}
```

### Label matchers

| Operator | Meaning |
|---|---|
| `label="value"` | Exact match |
| `label!="value"` | Negative exact match |
| `label=~"regex"` | Regex match |
| `label!~"regex"` | Negative regex match |

---

## Gorilla compression

Each series chunk stores samples as a stream of XOR-encoded deltas:

- **Timestamps** — delta-of-delta encoded with variable-length bit packing (DFCM).
- **Values** — XOR of consecutive float64 values; leading/trailing zero bits stored as control bits, only the meaningful bits written.

A chunk of 120 samples (2 hours at 1-minute resolution) typically compresses to **~1.4 bytes per sample**, vs 16 bytes raw (timestamp + float64).

---

## Write-ahead log format

```
[ CRC32: 4B ][ length: 4B ][ series_id: 8B ][ timestamp: 8B ][ value: 8B ]
```

On startup, entries are replayed in order. Entries with a mismatched CRC32 (indicating a torn write) are discarded — the last intact entry wins.

---

## CLI flags

| Flag | Default | Description |
|---|---|---|
| `--listen` | `0.0.0.0:9090` | HTTP listen address |
| `--data-dir` | `./data` | Directory for WAL and block files |
| `--wal-sync` | `true` | `fsync` after every WAL append |
| `--chunk-duration` | `7200` | Seconds before sealing an active chunk |

---

## Limitations

- **No retention** — blocks accumulate until disk is full. A compaction pass that merges and drops old blocks is planned.
- **Single node** — no replication or federation.
- **No TLS / auth** — suitable for trusted internal use; add a reverse proxy for exposure.
- **WAL replay only** — no point-in-time recovery beyond the current WAL segment.

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:291500,50:1a0d00,100:0d1117&height=80&section=footer" />
</div>
