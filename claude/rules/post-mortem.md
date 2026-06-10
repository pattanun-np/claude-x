<!-- post-mortem v1·2026-05-24·source 9arm-skills-main -->

# Post-mortem — Canonical Bug Fix Record

Required output format after non-trivial bug fix. Blameless tone enforced. Refuse without prereqs.

<inputs>
## 4 Required Inputs (refuse if any missing)
1. **Reproduction** — exact steps + raw command + raw output that produces the bug.
2. **Root cause** — verified via ≥3 hypotheses falsified (see debug-mantra §falsify).
3. **Fix** — diff or commit SHA, with file:line citation.
4. **Validation** — what test/probe confirms the fix; what was re-run; raw exit code.

Missing any → `BLOCKED prereq: <which input missing>·(a)gather (b)stop`. Do NOT generate a partial post-mortem.
</inputs>

<structure>
## 9-Section Template (in order)

### 1. Title
`<surface>: <symptom> when <trigger>` — concrete, searchable. No "Fix the thing".

### 2. Summary (3-5 sentences max)
What happened, who was affected, when fixed. No code, no jargon a PM cannot read.

### 3. Timeline (UTC, RFC3339)
`HH:MM:SSZ event` lines. First report → diagnosis milestones → fix landed → verified.

### 4. Impact
- Surface affected (endpoint / user-segment / region).
- Users affected (count or fraction).
- Duration (start → end).
- Data integrity: any loss / corruption / dual-write divergence?
- $-impact if calculable.

### 5. Root Cause (verified)
What WAS the cause (not what was suspected). Cite tool_use_id for the verification. Confident-when-correct (ch§5).

### 6. Fix (diff or SHA)
What changed, what file:line, what test added. If no test → flag it as gap, do not hide it.

### 7. Validation
How the fix was confirmed. Commands run, exit codes, before-vs-after. Raw bytes only.

### 8. Prevention (actionable)
Concrete change. Forbidden: "be more careful", "improve testing in general", "tighten reviews".
Allowed: "Add property test for race on X", "Block path Y via type-system", "Wire alarm Z to SLO breach".

### 9. Lessons (blameless)
What the system allowed; not what the human got wrong. Forbidden: "Alice forgot to". Allowed: "The code path allowed null where invariant required non-null."
</structure>

<blameless>
## Blameless Tone (enforced)
- **Replace "X did Y wrong" with "Y was allowed because Z".**
- **Failures point at system gaps**, not at humans. Humans are the messengers.
- **Recommendations target system change**, never "be more careful".
- **No named blame in the document.** Names belong in private 1:1s, not artifacts.
- **The post-mortem outlives the incident.** Future readers should learn about the system, not gossip about the team.
</blameless>

<refuse>
## Hard Preconditions
- No repro → cannot write. Use debug-mantra §reproduce first.
- No verified root cause → cannot write. Use debug-mantra §falsify first.
- No fix landed → cannot write. Write as "in-flight incident report" instead.
- No validation → cannot claim "fixed". The fix is unconfirmed until validated.
- Tone-violation ("X should have known") → REJECT draft, rewrite blameless.
- PII in incident artifact → SCRUB per CLAUDE.md §10.11 (logs scrub, no PII metrics).
</refuse>
