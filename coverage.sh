#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OUTPUT_DIR=$(mkdir -p "$1" && cd "$1" && pwd)

# Change to module directory.
cd "${INPUT_MODULE-.}"

# Input file.
INPUT="${INPUT_COVERAGE-}"

# Get coverage for all packages in the current directory.
if [ -z "$INPUT" ]; then
	INPUT=$(mktemp)
	go test ./... -coverpkg "$(go list || go list -m | head -1)/..." -coverprofile "$INPUT"
fi

# Create an HTML report.
if [[ "${INPUT_REPORT-true}" == "true" ]]; then
	go tool cover -html="$INPUT" -o "$OUTPUT_DIR/coverage.html"
fi

# Extract total coverage: the decimal number from the last line of the function report.
COVERAGE=$(go tool cover -func="$INPUT" | tail -1 | grep -Eo '[0-9]+\.[0-9]')

echo "coverage: $COVERAGE% of statements"

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

# Change to output directory.
cd "$OUTPUT_DIR"

# Style for the badge.
STYLE="${INPUT_BADGE_STYLE-}"
# Title for the badge.
TITLE="${INPUT_BADGE_TITLE-}"

# Download the badge.
curl -s "https://img.shields.io/badge/$(printf %s "$TITLE" | jq -sRr @uri)-$COVERAGE%25-$COLOR?style=$STYLE" > coverage.svg

# Download the chart.
if [[ "${INPUT_CHART-false}" == "true" ]]; then
	# Add record.
	date "+%s,$COVERAGE" >> coverage.log

	LOG=$(mktemp)
	# Sort by date, remove duplicates.
	sort -u coverage.log > "$LOG"
	# Collapse spans with similar coverage.
	awk -F, '{ if (NR==1 || $2 != prev) { print; prev = $2 } } END { print }' "$LOG" > coverage.log

	if [[ $(wc -l < coverage.log) -le 2 ]]; then
		echo Insufficient records for coverage chart.
		exit
	fi

	GRADIENT='getGradientFillHelper("vertical",["#44CC11","#97CA00","#A4A61D","#DFB317","#FE7D37","#E05D44"])'

	jq -csf "$SCRIPT_DIR/chart.jq" "$SCRIPT_DIR/chart.json" <(
		tail -n 20 coverage.log | sed 's/.*/[&]/' | jq -s '.|transpose'
	) |
	sed s/\"__GRADIENT__\"/"$GRADIENT"/ |
	jq -csR '{format:"svg", chart:.}' |
	curl -sd @- -X POST -H 'Content-Type: application/json' https://quickchart.io/chart > coverage-chart.svg
fi
