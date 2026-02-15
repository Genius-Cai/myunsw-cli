#!/bin/bash
# search-classes.sh — Search for UNSW classes
# Usage: ./search-classes.sh SUBJECT [CATALOG_NBR] [TERM]
# Example: ./search-classes.sh COMP 1511 5266

COOKIE="/tmp/myunsw_active.txt"
BASE="https://my.unsw.edu.au/active/studentClassSearch"
SUBJECT="${1:?Usage: $0 SUBJECT [CATALOG_NBR] [TERM]}"
CATALOG="${2:-}"
TERM="${3:-5263}"

if [ ! -f "$COOKIE" ]; then
    echo "Error: Cookie file not found at $COOKIE"
    exit 1
fi

echo "Loading search form..."
curl -s -L -b "$COOKIE" "$BASE/reset.xml" -o /tmp/_search.html
SEQ=$(grep -oP 'bsdsSequence" value="\K[0-9]+' /tmp/_search.html)

if [ -z "$SEQ" ]; then
    echo "Error: Session expired."
    exit 1
fi

PARAMS="bsdsSequence=$SEQ&term=$TERM&subject=$SUBJECT&bsdsSubmit-search="
if [ -n "$CATALOG" ]; then
    PARAMS="$PARAMS&catalogNbr=$CATALOG"
fi

echo "Searching: subject=$SUBJECT catalog=$CATALOG term=$TERM"
curl -s -L -b "$COOKIE" -d "$PARAMS" "$BASE/search.xml" -o /tmp/_search_results.html

# Check for results
if grep -q 'no results' /tmp/_search_results.html; then
    echo "No results found. Timetable may not be published for this term yet."
else
    echo "Results saved to /tmp/_search_results.html"
    # Count result rows
    COUNT=$(grep -c 'classSearchMinDetail\|classSearchMaxDetail' /tmp/_search_results.html)
    echo "Found approximately $COUNT class entries."
fi
