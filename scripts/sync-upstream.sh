#!/usr/bin/env bash
# Sync this fork with upstream deepseek-ai/deepseek-harness.
#
# Remotes:  mine = your fork (lanxiake/dsh-Veyra),  upstream = read-only source of truth.
# Branches: master = pristine upstream mirror (never commit here),
#           merge/local = your integration line (the branch you actually run).
#
# Usage:  scripts/sync-upstream.sh [ref]        # ref defaults to upstream/master
#         scripts/sync-upstream.sh dsh-v0.2.2-rc.2
set -euo pipefail

cd "$(dirname "$0")/.."
target="${1:-upstream/master}"

git fetch upstream --tags
git merge --ff-only upstream/master 2>/dev/null || true

# Refuse to start with a dirty tree: a conflict during sync would bury local edits.
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is dirty. Commit or stash first." >&2
  git status --short >&2
  exit 1
fi

echo "=== commits arriving from $target ==="
git log --oneline "merge/local..$target" | head -40
echo "=== end list ($(git rev-list --count "merge/local..$target") total) ==="

git checkout merge/local
git merge --no-ff "$target"

cat <<'EOF'

Merge finished (any conflicts are resolved and committed above).

Next, in order:
  pnpm install          # pnpm-lock.yaml almost certainly moved
  pnpm run build:check  # earliest, cheapest breaking-API signal

If build:check fails, an upstream public API moved. Look in
docs/upgrade-guide/<highest version>/ for the matching guide.
Otherwise continue with:
  pnpm run test
  pnpm run doc-sync
  <your own targeted tests>

For generated-file conflicts, take upstream and regenerate:
  pnpm run gen-tool-catalog gen-config-catalog gen-doc-graphs gen-cordis-catalog

Then publish your line:
  git push mine merge/local
EOF
