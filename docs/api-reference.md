# myUNSW API Reference

Complete documentation of all discovered myUNSW `/active/` endpoints.

## Base URL

```
https://my.unsw.edu.au/active/
```

Authentication: Cookie-based (`JSESSIONID` path=/active + `AWSALB`/`AWSALBCORS`)

---

## Enrollment Endpoints

### `studentClassEnrol/years.xml` (ENR2.YRS)

Entry point for enrollment.

**GET**: Returns year selection page
**POST**:
| Param | Value | Action |
|-------|-------|--------|
| bsdsSequence | (required) | Server-side CSRF |
| year | e.g. "2026" | Year to enroll |
| bsdsSubmit-update-enrol | any | Enter editable enrollment |
| bsdsSubmit-view-enrol | any | View historical (read-only) |

### `studentClassEnrol/courses.xml` (ENR2.CRS)

Course list and navigation hub.

**GET**: Returns courses page (if in CRS state)
**AJAX GET**: `?term=XXXX` returns "ok" (switches active term tab)
**POST**:
| Param | Value | Action |
|-------|-------|--------|
| bsdsSequence | (required) | |
| term | term code | Active term |
| course | course key | Target course |
| class | class number | Target class |
| search | text | Inline search |
| bsdsSubmit-select-classes | | → classes.xml |
| bsdsSubmit-view-timetable | | → timetable.xml |
| bsdsSubmit-manage-waitlist | | → waitlist |
| bsdsSubmit-search-courses | | → search (blank=advanced) |
| bsdsSubmit-course-info | | → course details |
| bsdsSubmit-class-info | | → class details |
| bsdsSubmit-drop-course | | ⚠️ DROPS immediately |
| bsdsSubmit-swap-course | | → swap flow |
| bsdsSubmit-submit-courses | | Confirm enrollment changes |
| selectCourses[] | course key(s) | Courses to confirm |

### `studentClassEnrol/classes.xml` (ENR2.CLS)

Class selection with calendar UI.

**GET**: Returns class selection page
**JSON API**: `?data=classes` returns structured JSON (see schema below)
**POST**:
| Param | Value | Action |
|-------|-------|--------|
| bsdsSequence | (required) | |
| classes | comma-separated cn | Selected class numbers |
| filter | JSON string | Filter state |
| bsdsSubmit-select | | Submit selection |
| bsdsSubmit-auto | | Auto-timetable |
| bsdsSubmit-back | | Return to courses |

### `studentClassEnrol/timetable.xml` (ENR2.TTBL)

Registered timetable view.

**GET**: Returns timetable page
**JSON API**: `?data=classes` returns compact JSON (registered classes only)
**POST**: `bsdsSubmit-back` to return

---

## JSON API Schema: `?data=classes`

```json
{
  "courses": [{
    "key": "06642415263T11",
    "enrolled": true,
    "registered": true
  }],
  "classes": [{
    "cn": 11198,
    "crs": "06642415263T11",
    "comp": "LEC|TUT|TLB|WEB|LAB",
    "includes": [11251],
    "excludes": [11199],
    "days": [1],
    "periods": [1],
    "face": true,
    "online": true,
    "registered": true,
    "waitlisted": true,
    "selected": true,
    "full": true,
    "stub": true,
    "show": "none|muted"
  }],
  "meetings": [{
    "cn": 11198,
    "title": "COMM1100 - LEC",
    "descr": "Clancy Aud",
    "day": 1,
    "start": "10:30:00",
    "end": "12:00:00",
    "clash": "warn|err|ok",
    "weeks": "1-5, 7, 9-10",
    "dates": ["2026-02-16", "2026-02-23"]
  }]
}
```

Field reference:
- `cn`: Class number (integer) — use in form submissions
- `comp`: Component type — LEC (lecture), TUT (tutorial), TLB (tutorial-lab), WEB (online component), LAB (laboratory)
- `days`: Array of weekdays (1=Mon through 7=Sun)
- `periods`: Time periods (1=before 1pm, 2=1pm-6pm, 3=after 6pm)
- `clash`: Timetable clash status — `warn` (allowed overlap), `err` (blocked), `ok` (no clash)

---

## Academic Endpoints

### `studentResults/results.xml`
View grades. POST with `term=CODE&bsdsSubmit-reload=Go` to switch terms.

### `studentAcadStatement/checkStatement.xml`
Academic statement. 3-step flow: reset.xml → checkStatement.xml (POST bsdsSubmit-commit=Y) → statement.pdf

### `studentTimetable/timetable.xml`
Official timetable. Also has `?data=classes` JSON API.

### `studentExam/exam.xml`
Exam timetable.

### `studentAcadStanding/standing.xml`
Academic standing. POST with term to switch.

---

## Personal Info Endpoints

All follow: GET reset.xml → actual page with BSDS form.

| Endpoint | Page ID | Index Param | Read | Write Actions |
|----------|---------|-------------|------|---------------|
| studentAddress/reset.xml | ADR1.0 | addressIndex | ✅ | add(-1), edit(N), accept |
| studentPhone/reset.xml | TEL1.0 | phoneIndex | ✅ | add(-1), edit(N), delete(N) |
| studentEmail/reset.xml | EML1.1 | emailIndex | ✅ | add(-1), edit(N), delete(N) |
| preferredName/reset.xml | UPRF1.0 | — | ✅ | commit (firstName, middleName) |
| emergencyContact/reset.xml | CON1.0 | emgContactIndex | ✅ | add(-1), edit(N), editPhone(N) |
| emergencySMS/reset.xml | SMS1.0 | — | ✅ | validate (register) |
| studentStatistics/reset.xml | STAT6.1a | — | ✅ | commit |
| statistics2/reset.xml | STAT6.1b | — | ✅ | commit |
| studentUsi/usi.xml | USI2.0 | — | ✅ | read-only |

Write pattern: POST with `bsdsSequence` + index param + `bsdsSubmit-{action}`

---

## Financial Endpoints

### `studentFees/reset.xml`
Fee statement list. POST `seleIndex=N&bsdsSubmit-done=View+Details` to view specific statement.
Expandable sections: `bsdsSubmit-course_expand`, `bsdsSubmit-fee_expand`
Payment: `bsdsSubmit-payment_option`

---

## Other Endpoints

### `studentClassSearch/search.xml`
Search parameters:
| Param | Type | Example |
|-------|------|---------|
| term | select | 5263 |
| subject | select | COMP (340 options) |
| catalogNbr | text | 1511 |
| freeText | text | "machine learning" |
| instructorName | text | |
| career | select | UGRD, PGRD, RSCH |
| instructionMode | select | P (in-person), DD (online), MM (multimodal) |
| location | select | KENSINGTON (112 options) |
| campus | select | KENS, COFA, ADFA |
| session | select | T1, T2, T3, KB (Hex1), etc. |
| faculty | select | COMP, COMM (15 options) |
| days[0-6] | checkbox | Y for Mon(0) through Sun(6) |
| startAfter | text | 09:00 |
| endBefore | text | 17:00 |

### `studentStreamChange/reset.xml`
Specialisation/major declaration. Actions: `bsdsSubmit-create_{program}_{award}`

### `concession/permission.xml`
Opal card data sharing. `permissionFlag=Y&bsdsSubmit-done=Grant+Permission`

### `termsConditions/reset.xml`
15 T&C checkboxes. `bsdsSubmit-done=Save`

### `IPT/reset.xml`
Internal program transfer. Application window displayed.

### `studentGraduand/reset.xml`
Graduation status.

### `disability/reset.xml`
ELS/disability declaration. Radio buttons for 11 condition types.

---

## Term Codes

| Code | Term | Code | Term |
|------|------|------|------|
| 5243 | T1 2024 | 5262 | Summer 2026 |
| 5246 | T2 2024 | 5263 | T1 2026 |
| 5249 | T3 2024 | 5266 | T2 2026 |
| 5253 | T1 2025 | 5269 | T3 2026 |
| 5256 | T2 2025 | 6610 | Hex1 2026 |
| 5259 | T3 2025 | 6630 | Hex2 2026 |

## Course Key Format

Pattern: `{catalogNbr}{strmDigit}{termCode}T{seq}`

Extract from courses.xml hidden inputs or JSON API — do not construct manually.
