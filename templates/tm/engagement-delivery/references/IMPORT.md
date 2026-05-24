# Import Protocol — <TM_NAME>

Steps a receiver follows to load an engagement-delivery TM. (Apply is a separate step — see `APPLY.md`.)

1. **Verify integrity:** `bash scripts/verify_tm.sh`. Refuse the TM if it exits non-zero.

2. **Read `references/TM.yml`** first. Check that `tm_spec_version` matches your toolchain's supported version. Note:
   - `source` — where the work was done. You don't need access to this; the TM author owns it.
   - `target` — where the TM applies. **This is your project.** Make sure `target.workspace` + `target.project` actually resolve under your `$INTERNOS_WORKSPACE`.
   - `deliverables[]` — what was built, where it lives, and how to talk to it.
   - `updates[]` — the file changes proposed against your target project.
   - `apply_protocol.preferred` — how the apply script will behave.

3. **Read `references/REDACTION_REPORT.md`.** Confirms what was checked/excluded; any sensitive-adjacent items still present are flagged here.

4. **Read `payload/runtime/USAGE.md`** if you'll be calling the deliverable. This is the operational documentation: env vars, endpoints, auth, example calls.

5. **Inspect `payload/updates/*`.** These are the actual content blocks that will be appended/replaced/merged into your target project. Apply ≠ accept — review before running the apply script.

6. **(Optional, for agent use of the deliverable)** Wire the MCP config into your agent harness:
   - Claude Code: append the entries from `payload/runtime/mcp.json` to your `.mcp.json` or the platform's MCP config location.
   - Hermes: install per Hermes conventions.
   - Other harnesses: see `payload/runtime/USAGE.md` for adapter notes.

7. **Apply when ready:** `bash scripts/apply_to_target.sh` (see `APPLY.md` for mode details).

## Do not

- Apply auto-magically. Every engagement-delivery TM requires human review of the proposed updates.
- Embed the deliverable source. The TM points at `deliverables[].repo`; clone that separately if you need the code.
- Modify `payload/` after import. Anything you change there breaks the integrity of the artifact you received.
