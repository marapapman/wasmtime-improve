# Performance Benchmark Automation

This folder provides an automated benchmark flow for Wasmtime using the
popular benchmark suites in
[`bytecodealliance/sightglass`](https://github.com/bytecodealliance/sightglass).

## CI/CD — GitHub-hosted Ubuntu runners

The workflow `.github/workflows/benchmark-aliyun.yml` runs benchmarks
automatically on GitHub-hosted `ubuntu-latest` runners.
No self-hosted runner setup is required.

After each run the workflow creates a GitHub issue containing the full
performance report.  GitHub will send a notification to your GitHub inbox
(and optionally via email) so you receive the results directly in your
GitHub mailbox.

### Workflow triggers

| Event | Condition | What happens |
|---|---|---|
| `push` to `main` | Always | Full benchmark run; results uploaded as artifacts and written to the job summary |
| `workflow_dispatch` | Manual trigger from the Actions UI | Configurable benchmark run — specify any branch, tag, or commit SHA in the `ref` input to benchmark a PR or release candidate |

### Customising the run

The workflow accepts four optional inputs when triggered via
`workflow_dispatch`:

| Input | Default | Description |
|---|---|---|
| `ref` | Current branch HEAD | Branch, tag, or commit SHA to benchmark (e.g. a PR head SHA) |
| `benchmark_suite` | `benchmarks/shootout.suite` | Suite path inside the sightglass checkout |
| `processes` | `3` | Number of benchmark processes |
| `iterations_per_process` | `3` | Iterations per process |

To benchmark against a stable baseline engine, set the repository
**variable** `BASELINE_ENGINE_PATH` (under *Settings → Secrets and variables
→ Actions → Variables*) to the absolute path of a pre-built
`libwasmtime_bench_api.so` available on the runner.

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
