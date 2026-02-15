# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Reverse-engineered myUNSW (UNSW Sydney student portal) API documentation + AI agent skills. No application code to build/test — the project distributes documentation, curl-based shell scripts, and skill files for multiple AI platforms.

## Project Architecture

```
├── SKILL.md                  # Root skill (YAML frontmatter + prompt) — the canonical skill definition
├── commands/myunsw.md        # Claude Code slash command (/myunsw)
├── AGENTS.md                 # Codex CLI agent instructions
├── .cursorrules              # Cursor rules
├── .claude-plugin/plugin.json # Plugin marketplace metadata
├── install.sh                # Auto-detect + install for Claude/Codex/OpenClawd
├── skills/                   # Legacy skill files (myunsw.md, AGENTS.md, GEMINI.md)
├── docs/
│   ├── api-reference.md      # All 27 endpoints, params, JSON schemas
│   ├── bsds-framework.md     # BSDS state machine reverse engineering
│   ├── deployment.md         # Multi-platform install guide (EN)
│   └── deployment_cn.md      # Multi-platform install guide (CN)
└── examples/                 # Standalone shell scripts (check-grades.sh, etc.)
```

## Key Technical Concept: BSDS Framework

Every myUNSW interaction follows this pattern — all scripts and skills encode it:

1. `GET page.xml` → extract `bsdsSequence` from hidden input
2. `POST` to **same URL** with `bsdsSequence` + `bsdsSubmit-{action}` + params
3. Follow `302` redirect → arrive at next state
4. Extract fresh `bsdsSequence`, repeat

The sequence is a server-side counter that increments on every page load. Stale values are silently ignored. All requests must be sequential.

## Cookie Requirements

All scripts expect `/tmp/myunsw_active.txt` in Netscape format with three cookies:
- `JSESSIONID` (path must be `/active`, not `/portal`)
- `AWSALB`
- `AWSALBCORS`

Session expires ~30 min. Validate: `curl -s -b /tmp/myunsw_active.txt 'https://my.unsw.edu.au/active/studentClassEnrol/years.xml' | grep -c 'bsdsSequence'`

## Editing Guidelines

- **SKILL.md** is the canonical skill definition — changes here should propagate to `commands/myunsw.md` and `skills/myunsw.md`
- `commands/myunsw.md` is the Claude Code slash command with `$ARGUMENTS` routing and full curl examples
- Term codes follow pattern: +3 per term (T1→T2→T3), ~+4 across year boundaries
- `bsdsSubmit-drop-course` drops immediately with NO confirmation — never include it in automated flows without explicit user consent
- Bilingual: English is primary, Chinese translations exist for README and deployment guide
