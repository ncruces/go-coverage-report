#!/usr/bin/env bash
set -euo pipefail

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
INPUT="${INPUT_COVERAGE-}"
OUTPUT="$1"

# Get coverage for all packages in the current directory.
if [ -z $INPUT ]; then
	INPUT=$(mktemp)
	go test ./... -coverpkg "$(go list)/..." -coverprofile "$INPUT"
fi

# Create an HTML report.
if [[ "${INPUT_REPORT-true}" == "true" ]]; then
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

# Style for the badge.
STYLE="${INPUT_BADGE_STYLE-}"

# Download the badge.
curl -s "https://img.shields.io/badge/coverage-$COVERAGE%25-$COLOR?style=$STYLE" > "$OUTPUT/coverage.svg"

# Download the chart.
if [[ "${INPUT_CHART-false}" == "true" ]]; then
	GRADIENT='getGradientFillHelper("vertical",["#44CC11","#97CA00","#A4A61D","#DFB317","#FE7D37","#E05D44"])'

	jq -csf "$DIR/chart.jq" "$DIR/chart.json" <(
		tail -n 20 "$OUTPUT/coverage.log" | sed 's/.*/[&]/' | jq -s '.|transpose'
	) |
	sed s/\"__GRADIENT__\"/$GRADIENT/ |
	jq -csR '{format:"svg", chart:.}' |
	curl -sd @- -X POST -H 'Content-Type: application/json' https://quickchart.io/chart > "$OUTPUT/coverage-chart.svg"
fi