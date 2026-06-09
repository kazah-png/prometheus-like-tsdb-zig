<div align="center">

# Prometheus-Like TSDB in Zig

**Time Series Database with Gorilla compression, WAL, and inverted index**  
Built from scratch in Zig – no dependencies, high performance, low latency.

[![Zig](https://img.shields.io/badge/Zig-0.13-orange?style=flat-square&logo=zig)](https://ziglang.org)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

</div>

## Overview

A minimal but powerful **time series database** inspired by Prometheus. Implements:

- **HTTP endpoints** for writing/reading metrics (Prometheus text exposition format).
- **Write-Ahead Log** for crash recovery.
- **Columnar storage** with Gorilla XOR compression (float) and DFCM (integer).
- **Inverted index** for fast label filtering.
- **Query language** supporting matchers (`{label="value"}`) and aggregations (`sum`, `avg`).

Written in **Zig** for maximum control over memory and performance – no GC, no runtime.

---

## Features

| Feature | Status |
|---------|--------|
| Scrape metrics (HTTP push) | ✅ |
| WAL persistence | ✅ |
| Gorilla compression | ✅ |
| Inverted index | ✅ |
| `sum` / `avg` / `max` queries | ✅ |
| Retention policies | ⏳ Planned |

---

## Quick Start

```bash
# Build with Zig (0.13+)
zig build

# Run
zig build run -- --listen 0.0.0.0:9090 --data-dir ./data

# Write a metric (via HTTP POST)
curl -X POST http://localhost:9090/api/v1/write \
  -d 'cpu_usage{instance="server1",core="0"} 42.5 1700000000'

# Query
curl 'http://localhost:9090/api/v1/query?query=cpu_usage{instance="server1"}'
Architecture
text
       HTTP /api/v1/write ──► WAL (disk)
               │
               ▼
         InvertedIndex ◄── Series (memory)
               │
               ▼
         Block (Gorilla) ──► Disk (mmap)
License
MIT

</div> ```