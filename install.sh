#!/bin/bash
# myunsw-cli installer
# Detects your AI tool and installs the appropriate skill file

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLED=0

echo "myunsw-cli installer"
echo "===================="

# Claude Code — slash command
if [ -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude/commands"
    cp "$REPO_DIR/commands/myunsw.md" "$HOME/.claude/commands/myunsw.md"
    echo "[+] Claude Code: installed /myunsw slash command"
    INSTALLED=1
fi

# Claude Code — skill (Agent Skills standard)
if [ -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude/skills/myunsw-cli"
    cp "$REPO_DIR/SKILL.md" "$HOME/.claude/skills/myunsw-cli/SKILL.md"
    [ -d "$REPO_DIR/docs" ] && cp -r "$REPO_DIR/docs" "$HOME/.claude/skills/myunsw-cli/references" 2>/dev/null
    echo "[+] Claude Code: installed skill to ~/.claude/skills/myunsw-cli/"
fi

# Codex CLI
if [ -d "$HOME/.codex" ]; then
    mkdir -p "$HOME/.codex/skills/myunsw-cli"
    cp "$REPO_DIR/SKILL.md" "$HOME/.codex/skills/myunsw-cli/SKILL.md"
    echo "[+] Codex CLI: installed skill to ~/.codex/skills/myunsw-cli/"
    INSTALLED=1
fi

# OpenClawd
if [ -d "$HOME/.openclawd" ]; then
    mkdir -p "$HOME/.openclawd/skills"
    cp "$REPO_DIR/commands/myunsw.md" "$HOME/.openclawd/skills/myunsw.md"
    echo "[+] OpenClawd: installed skill"
    INSTALLED=1
fi

if [ "$INSTALLED" -eq 0 ]; then
    echo ""
    echo "No AI tool detected. Manual install options:"
    echo ""
    echo "  Claude Code:  cp commands/myunsw.md ~/.claude/commands/myunsw.md"
    echo "  Codex CLI:    cp AGENTS.md /your/project/AGENTS.md"
    echo "  Gemini CLI:   cp skills/GEMINI.md /your/project/GEMINI.md"
    echo "  Cursor:       cp SKILL.md .cursor/rules/myunsw.md"
    echo "  Windsurf:     cp SKILL.md .windsurfrules/myunsw.md"
fi

echo ""
echo "Done. Usage: /myunsw setup"
