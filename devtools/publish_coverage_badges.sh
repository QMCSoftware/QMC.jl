#!/usr/bin/env bash
set -euo pipefail

: "${BADGE_BRANCH:?BADGE_BRANCH is required}"
: "${BADGE_DIR:?BADGE_DIR is required}"
: "${COVERAGE_SCOPE:?COVERAGE_SCOPE is required}"
: "${COVERAGE_LABEL:?COVERAGE_LABEL is required}"
: "${LCOV_PATH:?LCOV_PATH is required}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_REF_NAME:?GITHUB_REF_NAME is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"
: "${GITHUB_RUN_NUMBER:?GITHUB_RUN_NUMBER is required}"
: "${GITHUB_RUN_ATTEMPT:?GITHUB_RUN_ATTEMPT is required}"

scope_slug="$(printf '%s' "$COVERAGE_SCOPE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g')"
branch_slug="$(printf '%s' "$GITHUB_REF_NAME" | sed 's#/#-#g')"
badge_file="coverage-${scope_slug}-${branch_slug}.json"
source_manifest_file="coverage-source-${scope_slug}-${branch_slug}.json"

test -f "$BADGE_DIR/$badge_file"
test -f "$BADGE_DIR/$source_manifest_file"
test -f "$LCOV_PATH"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cd "$tmpdir"

git init
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
if git ls-remote --exit-code --heads origin "$BADGE_BRANCH" >/dev/null 2>&1; then
  git fetch --depth=1 origin "$BADGE_BRANCH"
  git checkout -b "$BADGE_BRANCH" FETCH_HEAD
else
  git checkout --orphan "$BADGE_BRANCH"
fi

mkdir -p badges
cp "$BADGE_DIR/$badge_file" "badges/$badge_file"
cp "$BADGE_DIR/$source_manifest_file" "badges/$source_manifest_file"

snapshot_dir="archive/coverage/${scope_slug}/${GITHUB_REF_NAME}/${COVERAGE_LABEL}"
mkdir -p "$snapshot_dir"
cp "$LCOV_PATH" "$snapshot_dir/lcov.info"
cp "$BADGE_DIR/$source_manifest_file" "$snapshot_dir/"

cat > "$snapshot_dir/manifest.json" <<EOF
{
  "branch": "${GITHUB_REF_NAME}",
  "scope": "${scope_slug}",
  "label": "${COVERAGE_LABEL}",
  "commit_sha": "${GITHUB_SHA}",
  "run_id": "${GITHUB_RUN_ID}",
  "run_number": "${GITHUB_RUN_NUMBER}",
  "run_attempt": "${GITHUB_RUN_ATTEMPT}",
  "badge_file": "badges/${badge_file}",
  "source_manifest": "badges/${source_manifest_file}",
  "archived_files": [
    "lcov.info",
    "${source_manifest_file}"
  ]
}
EOF

mkdir -p "archive/coverage/${scope_slug}/${GITHUB_REF_NAME}"
cat > "archive/coverage/${scope_slug}/${GITHUB_REF_NAME}/latest.json" <<EOF
{
  "branch": "${GITHUB_REF_NAME}",
  "scope": "${scope_slug}",
  "label": "${COVERAGE_LABEL}",
  "commit_sha": "${GITHUB_SHA}",
  "snapshot_dir": "${snapshot_dir}",
  "source_manifest": "badges/${source_manifest_file}"
}
EOF

cat > README.md <<'EOF'
Benchmark and coverage badge JSON plus archived source snapshots for Shields.io.
Latest badge source manifests live under `badges/`.
Historical benchmark snapshots live under `archive/<branch>/<label>/`.
Historical coverage snapshots live under `archive/coverage/<scope>/<branch>/<label>/`.
EOF

git add badges archive README.md
git commit -m "Update coverage badge ${scope_slug} for ${GITHUB_SHA}" || exit 0

for attempt in 1 2 3 4 5; do
  if git push origin HEAD:"$BADGE_BRANCH"; then
    exit 0
  fi
  git fetch --depth=1 origin "$BADGE_BRANCH"
  git rebase "origin/$BADGE_BRANCH"
done

echo "Failed to publish coverage badge after 5 attempts" >&2
exit 1
