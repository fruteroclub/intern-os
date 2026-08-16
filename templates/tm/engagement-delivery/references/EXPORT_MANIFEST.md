# Export Manifest — <TM_NAME>

Type: `internOS.engagement-delivery`
Spec version: 1.1
Created: <ISO8601>

## Provenance

- Authored on: <hostname or environment>
- Author identity: <AUTHOR>
- Source project: `workspaces/<SOURCE_WORKSPACE>/projects/<SOURCE_PROJECT>` at commit `<git-sha-or-snapshot-id>`
- Target project: `workspaces/<TARGET_WORKSPACE>/projects/<TARGET_PROJECT>` at commit `<git-sha-or-null>`
- Deliverable repo: `<deliverable-repo>` at commit `<deliverable-git-sha>`

## What this TM contains

- `payload/updates/` — file-level operations against the target project
- `payload/runtime/` — operational handles (MCP config, per-skill SKILL.md, USAGE)
- `payload/source-snapshot/` — (optional) provenance snippets from the source

## What this TM does NOT contain

- Source project state beyond what's necessary for provenance.
- The deliverable's source code (lives in `deliverables[].repo`).
- Target project state (the receiver already has it; the TM proposes changes against it).
- Credentials, tokens, secrets, or any harness identity.

## Reproducing this export

This TM was produced manually. A future `intern-os tm export-delivery <source>/<target>` command will automate the process from declarative inputs; until then, follow `docs/specs/transfer-modules.md` § "Type: internOS.engagement-delivery" in the `poktalabs/intern-os` repo.
