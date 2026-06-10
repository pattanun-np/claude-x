<!-- scrutinize v1·2026-05-24·source 9arm-skills-main -->

# Scrutinize — Outsider Code Review

Extends CLAUDE.md §5.5 (Code review). Apply when reviewing code (yours or others') for production fitness.

<intent>
## Intent Check (mandatory first question)
**"Is there a simpler way to achieve the same outcome?"**
- Before any structural critique, ask if the entire approach is necessary.
- If simpler exists and meets requirements → recommend simpler; do not patch the complex version.
- "Complexity that doesn't pay for itself is debt." (CLAUDE.md §6.5)
- Signs of over-complexity: 3+ abstraction levels for 1 use, framework <50 lines, generic-for-1, "future-proof" with no caller.
</intent>

<outsider>
## Adopt Outsider Perspective
- **Read code as if you wrote nothing.** No mental shortcuts from authorship context.
- **Question every comment.** Code lies about itself; the comment may be stale.
- **Question every name.** `getUserV2` next to `getUser` = m5 cherry-pick. Why two?
- **Question every wrapper.** Wrappers / aliases / shims = §3 Zero violation unless §16 sanctioned.
- **Trust nothing the diff says about itself.** Verify against actual behavior.
</outsider>

<trace>
## Full Path Trace
- **Entry → middleware → service → repo → DB** (CLAUDE.md §3.2 bidir trace).
- **Down → Up → Caller's caller** (CLAUDE.md §8 BR recursive).
- **Read the surface that data reaches** (CLAUDE.md §8 1C). Where do end-users see this? Logs? Metrics?
- **Non-code blast radius** (CLAUDE.md §8 1D). DB schemas, API contracts, events, cron, webhooks, analytics, i18n, docs, tests, flags.
- **Stop only when frontier empty OR budget ≥30% AND new finds LOW** (CLAUDE.md §8).
</trace>

<verify>
## Verify, Do NOT Trust
- **Every claim → tool_use_id** (CLAUDE.md §2.1 3-link).
- **Code claims need file:line + snippet** (CLAUDE.md §2.7 cl1).
- **"It should work" = BLOCKED** (CLAUDE.md §5.1 cmd 3).
- **Tests pass ≠ correct.** Did the test test the right thing? (CLAUDE.md §2.10 traps)
- **Docs say ≠ behavior is.** Call the API, observe; do not trust docs.
- **2 agents agree = common-mode.** Need 3rd source, rank ≤3 (CLAUDE.md §2.7 cl6).
</verify>

<severity>
## Severity-Ordered Output
Flag only ≥80 confidence (CLAUDE.md §5.5). Skip pre-existing / linter-catchable / pedantic / stylistic / unmodified.

- **CRIT (≥60 conf)**: data loss, security, payments, auth, breaking contract, race on shared state.
- **HIGH (≥70 conf)**: production bug, perf regression >2×, missing observability for new path.
- **MED (≥80 conf)**: maintainability hazard, partial coverage, missing edge case.
- **LOW (≥90 conf)**: convention drift, naming, redundancy that compiles but compounds.

Per finding: `[SEVERITY] file:line — issue · why it matters · suggested fix`. No prose padding.
</severity>

<refuse>
## Hard Preconditions
- LGTM without Read → `BLOCKED:split PR` (CLAUDE.md §5.3).
- Diff too large to fully read → split or refuse.
- "Looks good based on pattern match" without trace → m13 vibes-review.
- Subagent says "PASS" without per-finding ev → re-check independently (CLAUDE.md §2.7 cl6).
- Reviewing your own work → outsider-perspective is ASPIRATIONAL not literal; partner with another agent or call advisor (CLAUDE.md §11.3 L2).
</refuse>
