# Release Automation

**Status:** Accepted
**Drafted:** 2026-04-12 (in `tmp/automated-release-plan.md`, graduated 2026-05-07)
**Scope:** Automate GitHub release creation when a version tag is pushed, using `CHANGELOG.md` as the source of release notes.

---

## Goal

Replace the current manual release flow (`gh release create v0.X.Y --notes "..."`) with a tag-triggered GitHub Actions workflow that extracts release notes from the matching `CHANGELOG.md` entry and creates the release.

This is the natural pair to a trunk-based branching model: PRs land on `main` continuously, and releases are explicit gestures (`git tag v0.X.Y && git push origin v0.X.Y`).

---

## Current process (manual)

1. PR merged to `main`.
2. `git pull origin main`.
3. `gh release create v0.X.Y --target main --title "..." --notes "..."`.
4. Manually paste release notes from `CHANGELOG.md`.

## Target process (automated)

1. PR merged to `main` (PR includes the `CHANGELOG.md` entry — already a checklist item).
2. `git tag v0.X.Y && git push origin v0.X.Y`.
3. GitHub Actions workflow extracts the matching `CHANGELOG.md` section and creates the GitHub release.

---

## Files to create

### 1. `.github/workflows/release.yml`

```yaml
name: Release

on:
  push:
    tags: ['v*']

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Extract version from tag
        id: version
        run: echo "tag=${GITHUB_REF#refs/tags/}" >> "$GITHUB_OUTPUT"

      - name: Extract release notes from CHANGELOG.md
        run: |
          bash intern-os/scripts/extract-changelog.sh "${{ steps.version.outputs.tag }}" > /tmp/release-notes.md
          if [ ! -s /tmp/release-notes.md ]; then
            echo "ERROR: No CHANGELOG.md entry found for ${{ steps.version.outputs.tag }}"
            exit 1
          fi

      - name: Create GitHub release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release create "${{ steps.version.outputs.tag }}" \
            --title "${{ steps.version.outputs.tag }}" \
            --notes-file /tmp/release-notes.md
```

**Design decisions:**

- `permissions: contents: write` — required for `gh release create` via `GITHUB_TOKEN`.
- Workflow fails explicitly if no `CHANGELOG.md` entry matches the tag — prevents empty releases.
- Title is just the tag (`v0.3.2`); the CHANGELOG entry contains any subtitle in the body.
- `--notes-file` (not `--notes`) avoids shell-escaping issues with markdown.
- No `--target` flag — the tag already points to the right commit.

### 2. `intern-os/scripts/extract-changelog.sh`

```bash
#!/usr/bin/env bash
#
# extract-changelog.sh — Extract release notes for a version from CHANGELOG.md
#
# Usage: bash extract-changelog.sh <version-tag>
#   e.g. bash extract-changelog.sh v0.3.2
#
# Outputs the CHANGELOG.md section for that version to stdout.
# Exit 0 if found (output may be non-empty), 1 if no matching entry.

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Usage: extract-changelog.sh <version-tag>" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
    echo "Error: $CHANGELOG not found" >&2
    exit 2
fi

awk -v ver="$VERSION" '
    /^## / {
        if (found) exit
        if (index($0, ver) > 0) { found=1; next }
    }
    found { print }
' "$CHANGELOG"
```

**Behavior:**

- Finds the line `## <version-tag>` (e.g. `## v0.3.2 — 2026-05-07`), matches on the version prefix only.
- Captures everything from that line until the next `## v` heading (or EOF).
- Strips the heading line itself (the workflow sets the release title separately).
- POSIX awk; works on macOS and Linux without dependencies.

**Edge cases:**

- Version not found → outputs nothing; workflow's `-s` check fails the job.
- Last entry in file → captures until EOF.
- `---` separators between entries → included; render as horizontal rules in GitHub release notes.

---

## Files to modify

### `CHANGELOG.md`

No format changes required. Existing format already works:

```markdown
## v0.3.2 — 2026-05-07

Content here...

---

## v0.3.1 — 2026-04-12
```

---

## Validation

### Local pre-merge check

```bash
bash intern-os/scripts/extract-changelog.sh v0.3.1
bash intern-os/scripts/extract-changelog.sh v0.3.0
bash intern-os/scripts/extract-changelog.sh v9.9.9   # nonexistent → empty output
```

### Workflow smoke test (after merge)

```bash
git tag v0.3.2-rc.1
git push origin v0.3.2-rc.1
# Expected: workflow runs, fails at "No CHANGELOG.md entry found" — confirms wiring works
git push origin --delete v0.3.2-rc.1
git tag -d v0.3.2-rc.1
```

---

## Rollout

1. Create `intern-os/scripts/extract-changelog.sh` and verify against existing CHANGELOG entries.
2. Create `.github/workflows/release.yml`.
3. Merge to `main` via PR (own commit, not bundled with feature work).
4. First real release using the new flow: **v0.3.2** (Hermes-native plumbing).

---

## What stays manual

- Writing the `CHANGELOG.md` entry (PR checklist item).
- Pushing the version tag (the intentional release gesture in trunk-based).
- Choosing the version bump (PATCH / MINOR / MAJOR per semver impact).

---

## Future enhancements (deferred)

- **Richer release titles** — parse `## v0.3.2 — Subtitle` and use it as the release title (`v0.3.2 — Subtitle`) instead of just the tag. Add a `--title` flag to `extract-changelog.sh`. Skipped now to keep v1 minimal.
- **Auto-tag on CHANGELOG bump** — workflow that watches for new `## v*` headings on `main` and auto-tags. More magic, more failure modes; skip until explicitly needed.
