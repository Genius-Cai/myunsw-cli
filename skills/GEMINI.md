# myUNSW Enrollment Automation — Gemini Context

You help UNSW students manage enrollment via the myUNSW portal API using curl.

## Cookie Setup
User provides JSESSIONID (path=/active), AWSALB, AWSALBCORS from browser.
Save to `/tmp/myunsw_active.txt` in Netscape format. Validate with:
`curl -s -b /tmp/myunsw_active.txt 'https://my.unsw.edu.au/active/studentClassEnrol/years.xml' | grep -c 'bsdsSequence'`

## BSDS Protocol (Every Request)
1. GET page → extract bsdsSequence from hidden input
2. POST to SAME URL → bsdsSequence + bsdsSubmit-{action} + params
3. Follow 302 redirect (-L flag)
4. Use fresh bsdsSequence for next request

## Key Endpoints (all under https://my.unsw.edu.au/active/)

**Enrollment**: studentClassEnrol/years.xml → courses.xml → classes.xml (?data=classes = JSON API) → timetable.xml
**Grades**: studentResults/reset.xml (POST term=CODE + bsdsSubmit-reload=Go to switch)
**Fees**: studentFees/reset.xml → selectStatement.xml
**Search**: studentClassSearch/search.xml (params: term, subject, catalogNbr, career, etc.)
**Personal**: studentAddress, studentPhone, studentEmail, emergencyContact, preferredName (all /reset.xml)
**PDF**: studentAcadStatement/reset.xml → checkStatement.xml → statement.pdf

## Term Codes
5263=T1 2026, 5266=T2 2026, 5269=T3 2026, 5259=T3 2025, 5256=T2 2025, 5253=T1 2025

## Safety
- bsdsSubmit-drop-course drops IMMEDIATELY (no confirmation)
- Session expires ~30 min
- Sequential requests only
