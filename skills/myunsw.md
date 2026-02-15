# myUNSW CLI — UNSW Student Portal Automation

Automate myUNSW operations (enrollment, grades, timetable, fees, personal info) via AI agent + curl.

**Usage**: `/myunsw $ARGUMENTS`

Examples:
- `/myunsw setup` — First-time cookie setup
- `/myunsw status` — Check enrollment & timetable
- `/myunsw grades` — View all grades & WAM
- `/myunsw enrol COMP1521` — Start enrollment flow
- `/myunsw fees` — View fee statements
- `/myunsw search COMP T2` — Search classes
- `/myunsw timetable` — View current timetable as JSON
- `/myunsw personal` — View personal info
- `/myunsw waitlist` — Check waitlist positions

---

## 0. First-Time Setup

If `/tmp/myunsw_active.txt` doesn't exist or session is expired, **ask the user**:

> Please log in to https://my.unsw.edu.au in your browser, then:
> 1. Open DevTools (F12) → Application → Cookies → my.unsw.edu.au
> 2. Copy `JSESSIONID` (path must be `/active`, NOT `/portal`)
> 3. Copy `AWSALB` and `AWSALBCORS`
> Paste all three values.

Then write cookie file:
```bash
cat > /tmp/myunsw_active.txt << 'COOKIE'
my.unsw.edu.au	FALSE	/active	FALSE	0	JSESSIONID	{VALUE}
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALB	{VALUE}
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALBCORS	{VALUE}
COOKIE
```

Validate:
```bash
curl -s -b /tmp/myunsw_active.txt 'https://my.unsw.edu.au/active/studentClassEnrol/years.xml' | grep -c 'bsdsSequence'
# 1 = valid, 0 = expired
```

---

## 1. Architecture

### Session Layers
```
Browser → CAS SSO (sso.unsw.edu.au) → Portal (/portal JSESSIONID) — DON'T USE
                                     → Active (/active JSESSIONID) — USE THIS
```

### BSDS Framework (Every Request)
```
1. GET page          → extract bsdsSequence from hidden input
2. POST to SAME URL  → bsdsSequence + bsdsSubmit-{action} + params
3. Follow 302        → next page
4. Repeat with fresh bsdsSequence
```

Rules:
- bsdsSequence increments every page load — always use freshest
- Stale sequence = silently ignored
- Sequential only — no parallel requests
- POST target = current URL, not destination

Helper:
```bash
COOKIE="/tmp/myunsw_active.txt"
BASE="https://my.unsw.edu.au/active"
extract_seq() { grep -oP 'bsdsSequence" value="\K[0-9]+' "$1"; }
```

---

## 2. Enrollment State Machine

```
ENR2.YRS  years.xml ──→ ENR2.CRS  courses.xml
                           ├─ select-classes  → ENR2.CLS  classes.xml
                           │                     └─ ?data=classes → JSON API (ALL classes)
                           ├─ view-timetable  → ENR2.TTBL timetable.xml
                           │                     └─ ?data=classes → JSON API (registered)
                           ├─ manage-waitlist → ENR2.WAIT
                           ├─ search-courses  → ENR2.SRCH
                           ├─ drop-course     → ⚠️ DROPS IMMEDIATELY
                           └─ ?term=XXXX      → "ok" (switch tab)
```

### Enrollment Flow
```bash
ENR="https://my.unsw.edu.au/active/studentClassEnrol"
YEAR="2026"; TERM="5263"; COURSE_KEY=""; CLASSES=""

# 1. Year selection
curl -s -b $COOKIE "$ENR/years.xml" -o /tmp/y.html
SEQ=$(extract_seq /tmp/y.html)

# 2. Enter year
curl -s -L -b $COOKIE -d "bsdsSequence=$SEQ&year=$YEAR&bsdsSubmit-update-enrol=Update+Enrolment" "$ENR/years.xml" -o /tmp/c.html
SEQ=$(extract_seq /tmp/c.html)

# 3. Switch term tab
curl -s -b $COOKIE "$ENR/courses.xml?term=$TERM"

# 4. Go to class selection
curl -s -L -b $COOKIE -d "bsdsSequence=$SEQ&term=$TERM&course=$COURSE_KEY&bsdsSubmit-select-classes=Select+Classes" "$ENR/courses.xml" -o /tmp/cl.html
SEQ=$(extract_seq /tmp/cl.html)

# 5. Get available classes (JSON!)
curl -s -b $COOKIE "$ENR/classes.xml?data=classes" | python3 -m json.tool

# 6. Select classes
curl -s -L -b $COOKIE -d "bsdsSequence=$SEQ&classes=$CLASSES&bsdsSubmit-select=" "$ENR/classes.xml" -o /tmp/confirm.html

# 7. Confirm (⚠️ may require browser)
```

---

## 3. JSON API: `?data=classes`

```json
{
  "courses": [{"key": "06642415263T11", "enrolled": true, "registered": true}],
  "classes": [{
    "cn": 11198, "crs": "06642415263T11", "comp": "LEC",
    "days": [1], "periods": [1], "face": true, "online": true,
    "registered": true, "waitlisted": true, "full": true,
    "includes": [], "excludes": [11199]
  }],
  "meetings": [{
    "cn": 11198, "title": "COMM1100 - LEC", "descr": "Clancy Aud",
    "day": 1, "start": "10:30:00", "end": "12:00:00",
    "clash": "warn", "weeks": "1-5, 7, 9-10", "dates": ["2026-02-16"]
  }]
}
```

---

## 4. Other Endpoints

### Grades (POST to switch terms)
```bash
curl -s -L -b $COOKIE "$BASE/studentResults/reset.xml" -o /tmp/r.html
SEQ=$(extract_seq /tmp/r.html)
curl -s -L -b $COOKIE -d "bsdsSequence=$SEQ&term=$TERM&bsdsSubmit-reload=Go" "$BASE/studentResults/results.xml"
```

### Academic Statement PDF
```bash
curl -s -L -b $COOKIE "$BASE/studentAcadStatement/reset.xml" -o /tmp/s.html
SEQ=$(extract_seq /tmp/s.html)
curl -s -L -b $COOKIE -d "bsdsSequence=$SEQ&bsdsSubmit-commit=Y" "$BASE/studentAcadStatement/checkStatement.xml"
curl -s -b $COOKIE "$BASE/studentAcadStatement/statement.pdf" -o /tmp/statement.pdf
```

### Fees
```bash
curl -s -L -b $COOKIE "$BASE/studentFees/reset.xml" -o /tmp/f.html
SEQ=$(extract_seq /tmp/f.html)
curl -s -L -b $COOKIE -d "bsdsSequence=$SEQ&seleIndex=0&bsdsSubmit-done=View+Details" "$BASE/studentFees/selectStatement.xml"
```

### Class Search (15+ params)
```bash
curl -s -L -b $COOKIE "$BASE/studentClassSearch/reset.xml" -o /tmp/cs.html
SEQ=$(extract_seq /tmp/cs.html)
curl -s -L -b $COOKIE -d "bsdsSequence=$SEQ&term=$TERM&subject=COMP&catalogNbr=1511&bsdsSubmit-search=" "$BASE/studentClassSearch/search.xml"
```

### Personal Info (all use reset.xml → BSDS pattern)
| Endpoint | Read | Write |
|----------|------|-------|
| studentAddress | ✅ | add/edit |
| studentPhone | ✅ | add/edit/delete |
| studentEmail | ✅ | add/edit/delete |
| preferredName | ✅ | save |
| emergencyContact | ✅ | add/edit |

### Other: standing, fees, specialisation, Opal card, T&C, IPT, graduation, disability

---

## 5. Term Codes
| Code | Term | Code | Term |
|------|------|------|------|
| 5253 | T1 2025 | 5263 | T1 2026 |
| 5256 | T2 2025 | 5266 | T2 2026 |
| 5259 | T3 2025 | 5269 | T3 2026 |

---

## 6. Best Practices
- Always validate session before operations
- Never reuse bsdsSequence — extract fresh after every request
- Save responses to /tmp/ for debugging
- `bsdsSubmit-drop-course` has NO confirmation — drops immediately
- Session expires ~30 min

## 7. Error Detection
```bash
grep -c 'cas/login' response.html    # >0 = session expired
grep -c 'bsdsSequence' response.html # 0 = not a valid page
grep -oP 'class="alert[^"]*"[^>]*>[^<]*<' response.html  # error messages
```

## 8. Argument Routing
| Argument | Action |
|----------|--------|
| `setup` | Ask for cookies, validate |
| `status` | Show enrolled courses & classes |
| `timetable` | Return timetable JSON |
| `grades [term]` | Fetch grades |
| `enrol [course]` | Enrollment flow |
| `search [subject] [term]` | Class search |
| `waitlist` | Waitlist positions |
| `fees` | Fee statements |
| `personal` | Address, phone, email |
| `statement` | Download PDF |
| `standing` | Academic standing |
| (empty) | Show help |
