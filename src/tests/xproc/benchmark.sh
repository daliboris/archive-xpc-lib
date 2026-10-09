#!/usr/bin/env bash
# Measures the scenarios of benchmark.xpl from outside (wall-clock time of the whole processor run).
# Usage: benchmark.sh [calabash|morgana] [runs] [extra options as name=value ...]
#   e.g. benchmark.sh morgana 3 levels=5 branching=3
# SKIP_GENERATE=1 reuses an existing tree (it must have been generated with the same options).
# Each scenario runs in a fresh JVM; scenario "none" gives the start-up time to subtract.
# Results go to ../output/benchmark/benchmark-<processor>.tsv.
set -euo pipefail

processor="${1:-morgana}"
runs="${2:-3}"
shift $(( $# > 2 ? 2 : $# ))
extra=("$@")

cd "$(dirname "$0")"
out_dir="../output/benchmark"
mkdir -p "$out_dir"
tsv="$out_dir/benchmark-$processor.tsv"

scenarios=(none
	root-d1 root-d2 root-d3 root-dfull root-dfull-all
	root-d2-dict1 root-dfull-dict1
	dict1-d1 dict1-dfull dict1-dfull-l1
	archive-dict1-d1 archive-dict1-dfull archive-root-dfull-dict1 archives-dict1)

run() { # run <scenario> -> prints the result element
	local args=("scenario=$1" "${extra[@]}")
	case "$processor" in
		calabash) xmlcalabash benchmark.xpl "${args[@]}" ;;
		morgana) morgana benchmark.xpl "${args[@]/#/-option:}" ;;
		*) echo "Unknown processor: $processor" >&2; exit 1 ;;
	esac
}

now_ms() { date +%s%3N; }

result_of() { # joins the processor output into one line and extracts the result element
	tr '\n\t' '  ' | tr -s ' ' | grep -o '<dxt:result[^>]*>' | sed 's/ xmlns:dxt="[^"]*"//' || echo 'FAILED'
}

if [[ "${SKIP_GENERATE:-0}" != 1 ]]; then
	echo "Generating tree (${extra[*]:-defaults}) ..." >&2
	generated=$(run generate 2>&1 | result_of)
	if [[ "$generated" == FAILED ]]; then
		echo "Tree generation failed; run 'scenario=generate' by hand to see the error." >&2
		exit 1
	fi
	echo "$generated" >&2
fi

printf 'scenario\trun\tms\tresult\n' > "$tsv"
for s in "${scenarios[@]}"; do
	for ((i = 1; i <= runs; i++)); do
		t0=$(now_ms)
		result=$(run "$s" 2>/dev/null | result_of)
		t1=$(now_ms)
		printf '%s\t%d\t%d\t%s\n' "$s" "$i" $((t1 - t0)) "$result" | tee -a "$tsv"
	done
done
echo "Results: $tsv" >&2
