# Performance Benchmark Automation

This folder provides an automated benchmark flow for Wasmtime using the
popular benchmark suites in
[`bytecodealliance/sightglass`](https://github.com/bytecodealliance/sightglass).

## What it does

`run_benchmarks.sh` will:

1. Download the latest `sightglass` benchmark suite source.
2. Build this repository's `wasmtime-bench-api` shared library.
3. Run the selected benchmark suite automatically.
4. Collect raw JSON benchmark results.
5. Generate both an HTML report and a markdown summary with run details.

## Usage

From the repository root:

```bash
./performance_benchmark/run_benchmarks.sh
```

Optional comparison against a baseline engine:

```bash
BASELINE_ENGINE_PATH=/tmp/wasmtime_main.so ./performance_benchmark/run_benchmarks.sh
```

Useful environment overrides:

- `BENCHMARK_SUITE` (default: `benchmarks/shootout.suite`)
- `PROCESSES` (default: `3`)
- `ITERATIONS_PER_PROCESS` (default: `3`)
- `SIGHTGLASS_REF` (default: `main`)

## Output

Generated files are written under `performance_benchmark/output/`:

- `summary.txt` - terminal-style benchmark summary
- `results.json` - raw benchmark output
- `report.html` - detailed HTML statistics report
- `report.md` - markdown summary with run metadata and artifact locations

When a `.suite` file is used, the runner automatically skips entries that do
not have a built `.wasm` file in the downloaded suite checkout.
