<!-- management-talk v1·2026-05-24·source 9arm-skills-main -->

# Management-Talk — Engineering → Leadership Translation

Channel-specific output shapes for translating engineering work to product/leadership/stakeholders.

<rules>
## Translation Rules
- **Strip code-level identifiers** — no symbol names, file paths, stack traces unless they're a deliverable.
- **Keep product/business identifiers** — JIRA / Linear ticket IDs, PR numbers, product names, customer segments.
- **Lead with the ask or status** — leadership reads top-down. The ask must be the first sentence.
- **Time-box the work** — "by Thursday", "this sprint", "next quarter". No "soon" or "eventually".
- **Show consequence, not mechanism** — "Payments will be 2-3× slower for EU customers" not "We're adding 300ms latency on the auth middleware".
- **Numbers with denominators** — "3 of 12 endpoints" not "3 endpoints". (CLAUDE.md §5.1 cmd 6)
- **Active voice, named owners** — "Alex owns the rollback by Friday" not "Rollback will be addressed".
</rules>

<channels>
## Channel Shapes

### JIRA / Linear (ticket)
- **Title**: `<verb> <object> by <when>` — actionable, scannable, finite.
- **Description**: Why (1-2 lines), What (bullets), Acceptance criteria (testable), Links (PR / docs / incident).
- **Labels**: priority, surface, area. Match repo conventions.

### Slack (sync update)
- 3-5 lines max in the channel.
- **State** (🟢 green / 🟡 yellow / 🔴 red) → **what changed** → **what's next** → **what I need**.
- Threads for technical detail. Channel for status.
- No "FYI" without an ask or a follow-up needed.

### Standup (verbal)
- Yesterday: 1 line per item, completed only.
- Today: 1 line per item, with the ask if any.
- Blockers: name them concretely. "Waiting on X by Y" not "blocked".
- No code names that the team can't decode.

### Email (async, archival)
- **Subject**: `<action-needed> | <topic>` if you need a response. `<topic>` if pure FYI.
- **First sentence**: the ask or the conclusion. Background AFTER, never before.
- **Inline TLDR** if >5 sentences.
- **Sign off with concrete next step** — what happens next, by whom, by when.

### Meeting (real-time, expensive)
- Agenda BEFORE meeting. If you can't write the agenda, you don't need the meeting.
- **Decisions, not discussions** — what was decided, who owns the action, by when.
- Notes go to a durable place (doc / ticket) — Slack threads vanish.
- End with explicit asks: "X owns Y by Z".
</channels>

<antipatterns>
## Anti-Patterns
- **Tech-jargon dump** on PM/exec audience — Wrong reader (ch§3.phase-A.4).
- **"Quick win" without scope** — undefined scope = scope creep waiting to happen.
- **"It's complicated" as the whole answer** — name the 2-3 things that make it complicated.
- **Status without consequence** — "DB migration in progress" tells leadership nothing they can act on.
- **Asking for permission you have** — bias toward action; surface decisions, not requests-for-approval.
- **Burying the lede** — if the action is in paragraph 3, you've lost half the readers.
- **Closure without commitment** — "we'll see" / "tentatively" = no commitment = no progress.
</antipatterns>

<audience>
## Audience-Awareness
- **Engineer-to-engineer**: stack trace, file:line, raw error. Full technical surface.
- **Engineer-to-PM**: outcome, surface, customer-impact. NO code.
- **Engineer-to-exec**: dollars, risk, timeline. ONE chart, ONE ask.
- **Engineer-to-incident-channel**: state + what-changed + what-next. Live, terse, scannable.
- **Engineer-to-customer**: apology if owed, status, ETA, link to follow. No internal-team blame.
</audience>

<refuse>
## Hard Preconditions
- No clear audience → STOP. Ask the user "who reads this" or default to least-technical reader.
- No clear ask → STOP. If you can't summarize the ask in one sentence, you don't have an ask.
- Code-identifier in PM-facing copy → REJECT draft, rewrite without symbols.
- Blame in any channel → REJECT (see post-mortem §blameless).
- PII / customer-identifying details in wide channel → SCRUB before send (CLAUDE.md §10.11).
</refuse>
