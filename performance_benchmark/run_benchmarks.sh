#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORK_DIR="${SCRIPT_DIR}/.work"
OUT_DIR="${SCRIPT_DIR}/output"
SIGHTGLASS_REF="${SIGHTGLASS_REF:-main}"
SIGHTGLASS_TARBALL_URL="${SIGHTGLASS_TARBALL_URL:-https://codeload.github.com/bytecodealliance/sightglass/tar.gz/refs/heads/${SIGHTGLASS_REF}}"
BENCHMARK_SUITE="${BENCHMARK_SUITE:-benchmarks/shootout.suite}"
PROCESSES="${PROCESSES:-3}"
ITERATIONS_PER_PROCESS="${ITERATIONS_PER_PROCESS:-3}"
BASELINE_ENGINE_PATH="${BASELINE_ENGINE_PATH:-}"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'USAGE'
Usage: performance_benchmark/run_benchmarks.sh

Environment variables:
  SIGHTGLASS_REF              Ref used for sightglass download (default: main)
  SIGHTGLASS_TARBALL_URL      Optional full tarball URL for sightglass source
  BENCHMARK_SUITE             Suite path inside sightglass (default: benchmarks/shootout.suite)
  PROCESSES                   Number of benchmark processes (default: 3)
  ITERATIONS_PER_PROCESS      Iterations per process (default: 3)
  BASELINE_ENGINE_PATH        Optional baseline wasmtime bench API shared library for comparison
USAGE
  exit 0
fi

mkdir -p "${WORK_DIR}" "${OUT_DIR}" "${WORK_DIR}/sightglass-src"
rm -rf "${WORK_DIR}/sightglass-src"/*

curl -fsSL "${SIGHTGLASS_TARBALL_URL}" | tar -xz -C "${WORK_DIR}/sightglass-src" --strip-components=1

cargo build --manifest-path "${REPO_DIR}/Cargo.toml" --release -p wasmtime-bench-api

ENGINE_PATH="${REPO_DIR}/target/release/libwasmtime_bench_api.so"
if [[ "$(uname -s)" == "Darwin" ]]; then
  ENGINE_PATH="${REPO_DIR}/target/release/libwasmtime_bench_api.dylib"
elif [[ "$(uname -s)" == "MINGW"* || "$(uname -s)" == "MSYS"* || "$(uname -s)" == "CYGWIN"* ]]; then
  ENGINE_PATH="${REPO_DIR}/target/release/wasmtime_bench_api.dll"
fi

if [[ ! -f "${ENGINE_PATH}" ]]; then
  echo "Error: expected engine at ${ENGINE_PATH}" >&2
  exit 1
fi

ENGINE_ARGS=(--engine "${ENGINE_PATH}")
if [[ -n "${BASELINE_ENGINE_PATH}" ]]; then
  ENGINE_ARGS=(--engine "${BASELINE_ENGINE_PATH}" --engine "${ENGINE_PATH}")
fi

RAW_JSON="${OUT_DIR}/results.json"
TEXT_SUMMARY="${OUT_DIR}/summary.txt"
HTML_REPORT="${OUT_DIR}/report.html"
MARKDOWN_REPORT="${OUT_DIR}/report.md"
RESOLVED_SUITE="${OUT_DIR}/resolved.suite"

pushd "${WORK_DIR}/sightglass-src" > /dev/null
if [[ "${BENCHMARK_SUITE}" == *.suite && -f "${BENCHMARK_SUITE}" ]]; then
  : > "${RESOLVED_SUITE}"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    if [[ -f "${line}" ]]; then
      echo "$(pwd)/${line}" >> "${RESOLVED_SUITE}"
    elif [[ -f "benchmarks/${line}" ]]; then
      echo "$(pwd)/benchmarks/${line}" >> "${RESOLVED_SUITE}"
    fi
  done < "${BENCHMARK_SUITE}"
  if [[ ! -s "${RESOLVED_SUITE}" ]]; then
    echo "Error: no runnable benchmark wasm files found in ${BENCHMARK_SUITE}" >&2
    exit 1
  fi
  BENCHMARK_SUITE="${RESOLVED_SUITE}"
fi

cargo run --release -- \
  benchmark \
  --processes "${PROCESSES}" \
  --iterations-per-process "${ITERATIONS_PER_PROCESS}" \
  "${ENGINE_ARGS[@]}" \
  -- \
  "${BENCHMARK_SUITE}" | tee "${TEXT_SUMMARY}"

cargo run --release -- \
  benchmark \
  --raw \
  --output-format json \
  --output-file "${RAW_JSON}" \
  --processes "${PROCESSES}" \
  --iterations-per-process "${ITERATIONS_PER_PROCESS}" \
  "${ENGINE_ARGS[@]}" \
  -- \
  "${BENCHMARK_SUITE}"

REPORT_STATUS="generated"
if ! cargo run --release -- report --output-file "${HTML_REPORT}" "${RAW_JSON}"; then
  REPORT_STATUS="failed (need at least 3 samples per benchmark for statistical report)"
fi
popd > /dev/null

{
  echo "# Wasmtime Performance Benchmark Report"
  echo
  echo "- Timestamp (UTC): $(date -u '+%Y-%m-%d %H:%M:%S')"
  echo "- Benchmark suite: ${BENCHMARK_SUITE}"
  echo "- Process count: ${PROCESSES}"
  echo "- Iterations per process: ${ITERATIONS_PER_PROCESS}"
  echo "- Primary engine: ${ENGINE_PATH}"
  if [[ -n "${BASELINE_ENGINE_PATH}" ]]; then
    echo "- Baseline engine: ${BASELINE_ENGINE_PATH}"
  fi
  echo
  echo "## Summary Output"
  echo
  echo '```text'
  sed -n '1,160p' "${TEXT_SUMMARY}"
  echo '```'
  echo
  echo "## Artifacts"
  echo
  echo "- Raw data: ${RAW_JSON}"
  echo "- HTML report: ${HTML_REPORT}"
  echo "- HTML report status: ${REPORT_STATUS}"
  echo "- Text summary: ${TEXT_SUMMARY}"
} > "${MARKDOWN_REPORT}"

echo "Benchmark summary: ${TEXT_SUMMARY}"
echo "Raw benchmark data: ${RAW_JSON}"
echo "HTML report: ${HTML_REPORT}"
echo "Detailed markdown report: ${MARKDOWN_REPORT}"
