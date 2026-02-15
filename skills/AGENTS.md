# myUNSW Enrollment Automation — Codex Agent Instructions

You are an AI assistant that helps UNSW students manage their enrollment via the myUNSW portal API.

## Setup

The user must provide their session cookies from myUNSW. Save them to `/tmp/myunsw_active.txt` in Netscape cookie format:
```
my.unsw.edu.au	FALSE	/active	FALSE	0	JSESSIONID	{VALUE}
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALB	{VALUE}
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALBCORS	{VALUE}
```

Validate: `curl -s -b /tmp/myunsw_active.txt 'https://my.unsw.edu.au/active/studentClassEnrol/years.xml' | grep -c 'bsdsSequence'` (1=valid, 0=expired)

## Core Protocol: BSDS Framework

Every myUNSW request follows this pattern:
1. GET page → extract `bsdsSequence` from `<input type="hidden" name="bsdsSequence" value="NNNNN">`
2. POST to SAME URL with `bsdsSequence=NNNNN&bsdsSubmit-{action}=...` + other params
3. Follow 302 redirect with `-L` flag
4. Extract new bsdsSequence from response for next request

**Critical**: bsdsSequence changes with every page load. Always use the freshest value.

## Available Operations

### Check Enrollment Status
Navigate: years.xml → courses.xml → timetable.xml?data=classes (returns JSON)

### View Grades
GET studentResults/reset.xml → POST with term code + bsdsSubmit-reload=Go to switch terms

### Class Search
GET studentClassSearch/reset.xml → POST with subject, catalogNbr, term, etc.

### Download Academic Statement
GET studentAcadStatement/reset.xml → POST bsdsSubmit-commit=Y → GET statement.pdf

### View Fees
GET studentFees/reset.xml → POST seleIndex=0 + bsdsSubmit-done=View+Details

## Term Codes
5263=T1 2026, 5266=T2 2026, 5269=T3 2026

## Safety Rules
- NEVER use bsdsSubmit-drop-course (drops immediately, no confirmation)
- Final enrollment confirm (bsdsSubmit-submit-courses) may fail via curl
- Always validate session before operations
- Sequential requests only, no parallelization
