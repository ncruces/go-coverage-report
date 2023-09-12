#!/usr/bin/env bash
set -euo pipefail

INPUT="${INPUT_COVERAGE-}"
OUTPUT="$1"

if [ -z $INPUT ]; then
	# Get coverage for all packages in the current directory.
	INPUT=$(mktemp)
	go test ./... -coverpkg "$(go list)/..." -coverprofile "$INPUT"
fi

if [[ "${INPUT_REPORT-true}" == "true" ]]; then
	# Create an HTML report.
	go tool cover -html="$INPUT" -o "$OUTPUT/coverage.html"
fi

# Extract total coverage: the decimal number from the last line of the function report.
COVERAGE=$(go tool cover -func="$INPUT" | tail -1 | grep -Eo '[0-9]+\.[0-9]')

echo "coverage: $COVERAGE% of statements"

date "+%s,$COVERAGE" >> "$OUTPUT/coverage.log"
sort -u -o "$OUTPUT/coverage.log" "$OUTPUT/coverage.log"

# Pick a color for the badge.
if awk "BEGIN {exit !($COVERAGE >= 90)}"; then
	COLOR=brightgreen
elif awk "BEGIN {exit !($COVERAGE >= 80)}"; then
	COLOR=green
elif awk "BEGIN {exit !($COVERAGE >= 70)}"; then
	COLOR=yellowgreen
elif awk "BEGIN {exit !($COVERAGE >= 60)}"; then
	COLOR=yellow
elif awk "BEGIN {exit !($COVERAGE >= 50)}"; then
	COLOR=orange
else
	COLOR=red
fi

# Download the badge; store next to script.
curl -s "https://img.shields.io/badge/coverage-$COVERAGE%25-$COLOR" > "$OUTPUT/coverage.svg"

if [[ "${INPUT_CHART-false}" == "true" ]]; then
	# Download the chart; store next to script.
	curl -s -H "Content-Type: text/plain" --data-binary "@$OUTPUT/coverage.log" \
		https://go-coverage-report.nunocruces.workers.dev/chart/ > \
		"$OUTPUT/coverage-chart.svg" 
fi