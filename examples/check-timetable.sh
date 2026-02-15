#!/bin/bash
# check-timetable.sh — Get timetable as JSON from myUNSW
# Usage: ./check-timetable.sh [year] [term_code] [cookie_file]
# Example: ./check-timetable.sh 2026 5263

YEAR="${1:-2026}"
TERM="${2:-5263}"
COOKIE="${3:-/tmp/myunsw_active.txt}"
ENR="https://my.unsw.edu.au/active/studentClassEnrol"

if [ ! -f "$COOKIE" ]; then
    echo "Error: Cookie file not found at $COOKIE"
    exit 1
fi

echo "Navigating to timetable (year=$YEAR, term=$TERM)..."

# Step 1: Year selection
SEQ=$(curl -s -b "$COOKIE" "$ENR/years.xml" | grep -oP 'bsdsSequence" value="\K[0-9]+')
[ -z "$SEQ" ] && echo "Error: Session expired" && exit 1

# Step 2: Enter enrollment
curl -s -L -b "$COOKIE" \
    -d "bsdsSequence=$SEQ&year=$YEAR&bsdsSubmit-update-enrol=Update+Enrolment" \
    "$ENR/years.xml" -o /tmp/tt_courses.html
SEQ=$(grep -oP 'bsdsSequence" value="\K[0-9]+' /tmp/tt_courses.html)

# Step 3: Switch term
curl -s -b "$COOKIE" "$ENR/courses.xml?term=$TERM" > /dev/null

# Step 4: Navigate to timetable
curl -s -L -b "$COOKIE" \
    -d "bsdsSequence=$SEQ&term=$TERM&bsdsSubmit-view-timetable=View+Timetable" \
    "$ENR/courses.xml" -o /tmp/tt_timetable.html

# Step 5: Get JSON
echo ""
curl -s -b "$COOKIE" "$ENR/timetable.xml?data=classes" | python3 -m json.tool

echo ""
echo "(JSON also saved to stdout. Pipe to file: ./check-timetable.sh > timetable.json)"
