# Export Manifest — <TM_NAME>

Created: <ISO8601>
Source: `<absolute-source-path>`
Payload root: `payload/workspaces/<WORKSPACE>/projects/<PROJECT><WORKSTREAM_PATH_SUFFIX>/`

The payload preserves internOS project/workstream structure while excluding nested code repositories, runtime artifacts, and global identity files per `references/REDACTION_REPORT.md`.

## Provenance

- Authored on: <hostname or environment>
- Author identity: <AUTHOR>
- Source commit (if applicable): <git-sha>
- Spec version targeted: 1.0

## Reproducing this export

This TM was produced manually. A future `intern-os tm export` command will automate the process from the source workspace; until then, follow `docs/specs/transfer-modules.md` § Lifecycle in the `fruteroclub/intern-os` repo.
