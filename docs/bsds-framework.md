# BSDS Framework — Reverse Engineering Notes

## What is BSDS?

BSDS (Browser Session Data Sequence) is a custom server-side state machine framework used by myUNSW. It was likely developed in-house at UNSW as part of their legacy Java web application.

## How it works

Every page in myUNSW contains a hidden form field:

```html
<input type="hidden" name="bsdsSequence" value="12345">
```

This value is a **server-side counter** that:
1. Increments with every page view (GET or POST response)
2. Must be included in every POST request
3. Acts as a CSRF-like token (prevents replay attacks)
4. Enforces sequential navigation (no skipping states)

## State Machine

The server tracks which "page state" the user is on. Each state has a set of valid actions (submit buttons). Submitting an action transitions to a new state:

```
State A → (POST bsdsSubmit-action) → 302 redirect → State B
```

### Page State IDs

Each page has an ID shown in the footer (e.g., `ENR2.CRS`, `HIS1.2`, `ADR1.0`):

| ID | Module | Page |
|----|--------|------|
| ENR2.YRS | Enrollment | Year selection |
| ENR2.CRS | Enrollment | Course list |
| ENR2.CLS | Enrollment | Class selection |
| ENR2.TTBL | Enrollment | Timetable view |
| ENR2.WAIT | Enrollment | Waitlist management |
| ENR2.SRCH | Enrollment | Advanced search |
| ENR2.CRSI | Enrollment | Course info |
| ENR2.CLSI | Enrollment | Class info |
| HIS1.2 | Results | Grade summary |
| HIS1.1 | Statement | Academic statement |
| ADR1.0 | Address | Address management |
| TEL1.0 | Phone | Phone management |
| EML1.1 | Email | Email management |
| CON1.0 | Emergency | Emergency contacts |
| SMS1.0 | SMS | UNSW Alert registration |
| STAT6.1a | Statistics | Demographics page 1 |
| STAT6.1b | Statistics | Demographics page 2 |
| USI2.0 | USI | Unique Student Identifier |

## Submit Button Convention

All actions use named submit buttons with the pattern `bsdsSubmit-{action}`:

```html
<input type="submit" name="bsdsSubmit-select-classes" value="Select Classes">
```

Common actions:
- `bsdsSubmit-back` — return to previous page
- `bsdsSubmit-done` / `bsdsSubmit-commit` — confirm/save
- `bsdsSubmit-add` — add new record
- `bsdsSubmit-edit` — edit existing record
- `bsdsSubmit-delete` — delete record
- `bsdsSubmit-search` — submit search
- `bsdsSubmit-reload` — refresh with new parameters

## POST Pattern

All forms POST to themselves (empty `action` attribute):

```html
<form method="post">  <!-- no action = posts to current URL -->
  <input type="hidden" name="bsdsSequence" value="12345">
  <!-- other fields -->
  <input type="submit" name="bsdsSubmit-action" value="Button Text">
</form>
```

The server determines the next page based on which `bsdsSubmit-*` button was submitted, then responds with a 302 redirect.

## Sequence Behavior

```
GET years.xml           → bsdsSequence = 1000
POST years.xml (1000)   → 302 → GET courses.xml → bsdsSequence = 1002
POST courses.xml (1002) → 302 → GET classes.xml → bsdsSequence = 1004
```

The sequence typically increments by 2 (one for the POST processing, one for the redirect GET).

## Failure Modes

| Scenario | Result |
|----------|--------|
| Stale bsdsSequence | POST silently ignored, returns to default/previous page |
| Missing bsdsSequence | Same as stale |
| Wrong bsdsSubmit action for current state | Unpredictable, may error |
| Concurrent requests | Second request gets stale sequence |

## Hidden JSON APIs

Some pages expose AJAX endpoints that return JSON instead of HTML:

- `classes.xml?data=classes` — full class/meeting data (only in ENR2.CLS state)
- `timetable.xml?data=classes` — compact registered-only data (only in ENR2.TTBL state)
- `courses.xml?term=XXXX` — returns "ok" string (term tab switch, any CRS state)

These are used by the JavaScript calendar widget (fullcalendar.io based).

## JavaScript Components

Three main JS files power the enrollment UI:

| File | Size | Purpose |
|------|------|---------|
| enrolClasses-min.js | 12KB | Class selection, filter management, form helpers |
| enrolCalendar-min.js | 18KB | Calendar widget, clash detection, event rendering |
| common2018-min.js | 7KB | Tooltips, double-submit prevention, modals |

Key JS functions:
- `sendClasses()` — submits comma-separated class numbers
- `sendCourse()` / `sendClass()` — submits single course/class
- `sendFilter()` — submits filter JSON
- `toggleClass()` — selects/deselects a class in the calendar

## Anti-Automation

The final enrollment confirmation (`bsdsSubmit-submit-courses`) appears to have additional validation that may reject requests from non-browser clients. This could be:
- JavaScript-injected hidden fields
- Timing checks
- Referer validation
- Cookie flags

All other endpoints work normally with curl.
