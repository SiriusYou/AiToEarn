#!/usr/bin/env bash
# Start Claude Code in remote control server mode for the AiToEarn project.
# This allows you to continue your local session from any browser at claude.ai/code
# or from the Claude mobile app.
#
# Usage:
#   ./scripts/remote-control.sh                  # Start with defaults
#   ./scripts/remote-control.sh --capacity 8     # Limit concurrent sessions
#   ./scripts/remote-control.sh --spawn worktree # Isolate sessions in git worktrees
#
# Prerequisites:
#   - Claude Code v2.1.51+ (run: claude --version)
#   - Logged in via: claude /login
#   - Pro, Max, Team, or Enterprise subscription

set -euo pipefail

cd "$(dirname "$0")/.."

exec claude remote-control \
  --name "AiToEarn" \
  "$@"
