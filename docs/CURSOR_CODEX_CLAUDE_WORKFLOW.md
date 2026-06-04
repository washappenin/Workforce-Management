# CURSOR / CODEX / CLAUDE WORKFLOW

How AI coding assistants are used to build this backend under the checkpoint system.

## Core Principles

- The backend is the source of truth. Do not design it around the future Lovable frontend.
- Governance and documentation first; business features only after foundation is complete.
- Every checkpoint is independently testable and updates `CHECKPOINT_LOG.md` before moving forward.
- No skipping security, tests, or documentation.

## Per-Checkpoint Workflow

1. **Read governance** -- Confirm scope against this doc set (`BACKEND_ENGINEERING_BIBLE.md`, the relevant `*_RULES.md`, `ROLE_PERMISSION_MATRIX.md`).
2. **Set status** -- Mark the checkpoint `IN_PROGRESS` in `CHECKPOINT_LOG.md`.
3. **Implement within scope** -- Follow `Route -> Controller -> Service -> Repository -> Database`. Create the full 6-file module set.
4. **Write tests** -- Unit + Supertest integration + security/regression tests. No skipped required tests.
5. **Run checks** -- Typecheck, lint, full test suite (current + regression).
6. **Update docs** -- `API_CONTRACT.md`, `DATABASE_SCHEMA.md`, role matrix, and module rules as applicable.
7. **Evaluate pass/fail** -- Apply the checkpoint's documented pass/fail conditions.
8. **Record results** -- Update the checkpoint's tracking section (notes, tests, security, docs, frontend impact, signoff) and set `PASSED`/`FAILED`/`BLOCKED`.

## Roles of the Tools

- Use AI assistants (Cursor, Codex, Claude) for implementation, test authoring, and doc updates within the active checkpoint scope.
- Assistants must not invent endpoints, roles, or workflows outside the documented plan.
- Assistants must not weaken security to make tests pass.

## Definition of Done (per checkpoint)

- Scope implemented; out-of-scope items not touched.
- All required tests green (current + regression).
- Security and privacy rules satisfied and tested.
- Documentation updated.
- `CHECKPOINT_LOG.md` updated with status and tracking sections.

## Change Control

- After `API_CONTRACT.md` is frozen (Checkpoint 19), no breaking API changes.
- Any necessary change post-freeze is additive and documented.

## Handoff to Lovable

- Only after Checkpoints 0-19 are complete and the backend is on staging.
- Lovable consumes `API_CONTRACT.md`, `ROLE_PERMISSION_MATRIX.md`, and `FRONTEND_HANDOFF.md`. See `LOVABLE_FRONTEND_PLAN.md`.
