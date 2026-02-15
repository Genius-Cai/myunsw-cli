#!/bin/bash
# check-grades.sh — Fetch grades for all terms
# Usage: ./check-grades.sh

COOKIE="/tmp/myunsw_active.txt"
BASE="https://my.unsw.edu.au/active/studentResults"
TERMS=(5243 5246 5249 5253 5256 5259 5263)
NAMES=("T1_2024" "T2_2024" "T3_2024" "T1_2025" "T2_2025" "T3_2025" "T1_2026")

if [ ! -f "$COOKIE" ]; then
    echo "Error: Cookie file not found at $COOKIE"
    exit 1
fi

echo "Fetching results page..."
curl -s -L -b "$COOKIE" "$BASE/reset.xml" -o /tmp/_results.html
SEQ=$(grep -oP 'bsdsSequence" value="\K[0-9]+' /tmp/_results.html)

if [ -z "$SEQ" ]; then
    echo "Error: Session expired."
    exit 1
fi

for i in "${!TERMS[@]}"; do
    TERM="${TERMS[$i]}"
    NAME="${NAMES[$i]}"

    echo ""
    echo "=== $NAME (term=$TERM) ==="

    curl -s -L -b "$COOKIE" \
        -d "bsdsSequence=$SEQ&term=$TERM&bsdsSubmit-reload=Go" \
        "$BASE/results.xml" -o "/tmp/_results_${TERM}.html"

    SEQ=$(grep -oP 'bsdsSequence" value="\K[0-9]+' "/tmp/_results_${TERM}.html")

    # Extract grade rows
    python3 -c "
import re
with open('/tmp/_results_${TERM}.html') as f:
    html = f.read()
# Find WAM stats
wam = re.findall(r'<td class=\"data\">([\d.]+)</td>', html)
if len(wam) >= 5:
    print(f'  Units: {wam[0]} | Graded: {wam[1]} | Passed: {wam[2]} | WAM: {wam[3]} | Cum: {wam[4]}')
# Find course rows
rows = re.findall(r'<td class=\"data\">([A-Z]{4}\d{4})</td><td class=\"data\">(.*?)</td><td class=\"data\">.*?</td><td class=\"data\">([\d.]+)</td><td class=\"data\">([\d]*)</td><td class=\"data\">(\w*)</td>', html)
for code, desc, units, mark, grade in rows:
    print(f'  {code}  {mark:>3s}  {grade:>2s}  {desc}')
if not rows:
    print('  (no grades available)')
" 2>/dev/null
done
