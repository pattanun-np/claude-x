# Comment Discipline — Budget & Auto-Cleanup

Extends CLAUDE.md §3.4 (AI smells: restate-code comments, WHY not WHAT). Applies to every comment Claude writes or edits, any language.

<budget>
## Comment Budget (writing)
- **Default = no comment.** Code self-documents; comment ONLY a constraint the code cannot show: invariant, fail-mode, unit, external contract, WHY-this-not-that.
- **≤1 line per comment. Hard cap 2 lines** — 2nd line allowed only when dropping it loses a real constraint (security fail-mode, data-loss risk).
- **Density rule:** comment longer than the code it annotates = over budget. A config field NEVER earns a paragraph.
- Forbidden shapes: restating the next line · narrating history ("was X, now Y") · tutorial prose · explaining stdlib/framework behavior · multi-line essays on config fields/env vars · comments talking to the reviewer ("this fixes…").
- Durable explanations (architecture, threat model, ops runbook) → README/ADR/docs/schema `description` field — not inline comments.
</budget>

<canon>
## Canonical Compression Example
Over budget (5 lines on one YAML field):
```
// AES-256 (hex-encoded 32-byte) key for the OAuth token vault: encrypts
// third-party integration tokens, SMS credentials, and SSO client secrets at
// rest. Left blank in committed YAML — deploy injects it via ENCRYPTION_KEY.
// Empty/invalid leaves the vault AND enterprise SSO fail-closed (the AES-GCM
// encryptor errors, so ssoReady()=false and /v1/auth/sso/init returns 503).
```
On budget (1 line, constraint preserved):
```
// AES-256 vault key (hex, 32B); deploy injects ENCRYPTION_KEY — empty ⇒ vault+SSO fail-closed (503)
```
Test: keep ONLY what a reader cannot derive from code — injection source + fail-closed behavior. Everything else was restatement.
</canon>

<autoclean>
## Auto-Cleanup (editing)
- Every file you edit: condense every over-budget comment **inside the edited region** to budget in the same pass (fix-on-find, in-scope).
- Over-budget comments **outside** the edited region: report count + `file:line` list only; do NOT drive-by rewrite (scope lock CLAUDE.md §3.2 · silent creep = m8).
- Cleanup = COMPRESS, never delete information underivable from code (fail-modes, units, security behavior, ticket refs). Losing a constraint to hit budget = m8.
- Post-cleanup: re-read the diff before claiming (Yellow-tier, ch§3.phase-D.5).
</autoclean>

<never>
## Never Touch
- License/SPDX headers · shebangs · encoding cookies.
- Tool directives: `eslint-disable` · `@ts-expect-error`/`@ts-ignore` · `# noqa` · `# type: ignore` · `pragma` · `prettier-ignore` · `biome-ignore` · coverage/`istanbul` markers · region markers a tool consumes.
- Public-API doc contracts (JSDoc/docstring/rustdoc): trim prose, keep params/returns/throws that tooling renders.
- `TODO`/`FIXME` with ticket ref: keep the ref, may compress prose.
- A comment you don't understand = Chesterton's fence (CLAUDE.md §6.3): leave it + ask; "looks unnecessary" is ignorance, not license.
</never>

<refuse>
## Hard Preconditions
- Repo-wide comment strip ("delete all comments") → Red-tier destructive · user-confirm first.
- Constraint you cannot verify from code → keep it verbatim within the 2-line cap, or leave untouched + flag.
- Removal that changes tooling behavior (directives above) → BLOCKED.
</refuse>
