#!/bin/bash
# Mirrors the devcontainer setup (updateContentCommand + postCreateCommand)
# for Claude Code on the web sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

npm install --no-audit --no-fund

# Apply D1 migrations to the local database; wrangler skips migrations that
# have already been applied, so this is safe to re-run.
echo 'y' | npm run create-dev-database
