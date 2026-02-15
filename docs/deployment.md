# Deployment Guide

How to set up myunsw-cli on different AI coding platforms.

## Prerequisites

### Get Your Cookies (Two Methods)

#### Method 1: Chrome Extension (Recommended)

1. Install [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc) (free Chrome extension)
2. Log in to [myUNSW](https://my.unsw.edu.au)
3. Navigate to any `/active/` page (e.g. enrollment, results)
4. Click the extension icon → "Export" → save as `cookies.txt`
5. The file is already in Netscape format — ready to use!

```bash
# Move to expected location
mv ~/Downloads/cookies.txt /tmp/myunsw_active.txt
```

> **Tip**: The exported file contains ALL cookies for the domain. It works as-is, but only the `/active` JSESSIONID, AWSALB, and AWSALBCORS are needed.

#### Method 2: Manual DevTools

1. Log in to [myUNSW](https://my.unsw.edu.au)
2. Open DevTools (F12) → Application → Cookies → `my.unsw.edu.au`
3. Find and copy these three values:
   - `JSESSIONID` (path must be `/active`, NOT `/portal`)
   - `AWSALB`
   - `AWSALBCORS`
4. Create cookie file manually:

```bash
cat > /tmp/myunsw_active.txt << EOF
my.unsw.edu.au	FALSE	/active	FALSE	0	JSESSIONID	YOUR_VALUE
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALB	YOUR_VALUE
my.unsw.edu.au	FALSE	/	FALSE	0	AWSALBCORS	YOUR_VALUE
EOF
```

### Validate Session

```bash
curl -s -b /tmp/myunsw_active.txt \
  'https://my.unsw.edu.au/active/studentClassEnrol/years.xml' | grep -c 'bsdsSequence'
# 1 = valid, 0 = expired (need to re-login)
```

Session expires after ~30 minutes of inactivity.

---

## Platform Setup

### Claude Code

Claude Code uses slash commands from `~/.claude/commands/`.

```bash
# Clone the repo
git clone https://github.com/Genius-Cai/myunsw-cli.git
cd myunsw-cli

# Install the skill
cp skills/myunsw.md ~/.claude/commands/myunsw.md

# Now in Claude Code:
# /myunsw setup        ← first time, paste cookies
# /myunsw grades       ← check grades
# /myunsw status       ← enrollment status
# /myunsw timetable    ← get timetable JSON
```

The skill supports arguments: `/myunsw grades T3 2025`, `/myunsw search COMP`, etc.

### Codex CLI (OpenAI)

Codex reads `AGENTS.md` from the project root.

```bash
# Clone and enter project
git clone https://github.com/Genius-Cai/myunsw-cli.git
cd myunsw-cli

# Copy agent instructions to your working directory
cp skills/AGENTS.md /path/to/your/project/AGENTS.md

# Or symlink
ln -s $(pwd)/skills/AGENTS.md /path/to/your/project/AGENTS.md

# Use with Codex
codex "check my UNSW enrollment status"
codex "what are my grades for T3 2025?"
codex "search for COMP1511 classes in T2 2026"
```

### Gemini CLI (Google)

```bash
# Copy context file
cp skills/GEMINI.md /path/to/your/project/GEMINI.md

# Use with Gemini CLI
gemini "show my UNSW timetable"
gemini "check my UNSW fees"
```

### OpenClawd

```bash
# Copy skill to OpenClawd
mkdir -p ~/.openclawd/skills
cp skills/myunsw.md ~/.openclawd/skills/myunsw.md

# Use it
openclawd --skill myunsw "check enrollment status"
openclawd --skill myunsw "show grades for all terms"
```

### Claude.ai (Web)

1. Go to [claude.ai](https://claude.ai) → create a new Project
2. Click "Add to Project Knowledge"
3. Upload `skills/myunsw.md`
4. Start a conversation:
   > "I need help managing my UNSW enrollment. Here are my cookies: JSESSIONID=xxx, AWSALB=yyy, AWSALBCORS=zzz"

Claude will create the cookie file and execute curl commands via Artifacts or tool use.

### Cursor

```bash
# Add as Cursor rules
mkdir -p .cursor/rules
cp skills/myunsw.md .cursor/rules/myunsw.md

# Cursor will load this as context for AI assistance
```

### Windsurf

```bash
cp skills/myunsw.md .windsurfrules/myunsw.md
```

### Aider

```bash
# Add as context file
aider --read skills/myunsw.md

# Or add to .aider.conf.yml
# read:
#   - skills/myunsw.md
```

---

## Cookie File Tips

### Auto-refresh with Extension

Since sessions expire in ~30 min, you may need to re-export frequently:

1. Keep the myUNSW tab open in browser
2. When session expires, refresh the page (auto re-authenticates via CAS SSO)
3. Re-export with the cookies extension
4. `mv ~/Downloads/cookies.txt /tmp/myunsw_active.txt`

### Filter Cookies (Optional)

The extension exports ALL cookies. To keep only what's needed:

```bash
grep -E '(JSESSIONID|AWSALB)' ~/Downloads/cookies.txt > /tmp/myunsw_active.txt
```

### Cookie File Format

The Netscape cookie format (tab-separated):
```
domain	subdomains	path	secure	expiry	name	value
```

Example:
```
my.unsw.edu.au	FALSE	/active	FALSE	0	JSESSIONID	ABC123DEF456
my.unsw.edu.au	FALSE	/	FALSE	1739648000	AWSALB	xyz789
my.unsw.edu.au	FALSE	/	FALSE	1739648000	AWSALBCORS	xyz789
```
