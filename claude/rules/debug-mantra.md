<!-- debug-mantra v1·2026-05-24·source 9arm-skills-main -->

# Debug Mantra — Reproduction Discipline

Extends CLAUDE.md §5.4 (Debug 5-step). Required ritual before any debugging session.

<mantras>
## The Four Mantras (recite verbatim before debugging)
1. **When in doubt, REPRODUCE.** Cannot fix what cannot reproduce.
2. **The bug shows you exactly where to look.** Read the failure, not your model of it.
3. **Falsify before fix.** ≥3 hypotheses, eliminate ≥2 by evidence, fix the survivor.
4. **Breadcrumb the trail.** Every step tried, every output observed, what failed and what worked.
</mantras>

<reproduce>
## Reproduction Gate
- **Repro ≥3× consistently** before declaring a bug "real". Once = flake. Twice = pattern. Thrice = bug.
- **Repro must be MINIMAL.** Strip env to smallest set that still fails. Each removed variable = one ruled-out hypothesis.
- **Capture raw stderr verbatim.** Paraphrased errors = fabrication (CLAUDE.md §2.5).
- **No repro → no fix.** Filing report without repro = m26 prereq-fab. Say "cannot reproduce" honestly.
</reproduce>

<trace>
## Trace the Fail Path
- **Read errors top→bottom in raw form.** First stack frame is where state went wrong; last frame is where it crashed. Both matter.
- **Find the closest working example.** Diff against it; the delta is your suspect set.
- **Trace control flow through the failure point.** Not "what the code does" — what data flows into and out of THIS line.
- **No symptom-fix.** Fixing what you observe instead of what caused it = whack-a-mole.
</trace>

<falsify>
## Falsify ≥3 Hypotheses
- **Single-cause anchoring is a known failure** (ch§3.phase-B.9). Generate ≥3 candidate causes BEFORE testing any.
- **Steel-man the opposing view.** What would a competent skeptic predict? If you can't produce it, you haven't finished thinking.
- **The first confident explanation is usually wrong.** Contradicted hypothesis → do NOT stack a second confident explanation (ch§3.phase-B.7 — confabulation cascade).
- **Eliminate by evidence, not belief.** Each hypothesis falsified by ≥1 tool_use_id, raw output cited.
</falsify>

<breadcrumb>
## Breadcrumb Ledger
- **Every step tried, recorded.** What command, what input, what output. Skipping breadcrumbs = forgetting the path home.
- **Every output observed, preserved verbatim.** Not summarized. Raw bytes (CLAUDE.md §2.7 cl1).
- **Every "didn't work" labeled.** What failed, why, what was ruled out. The negative results are evidence too.
- **Every "worked" examined for luck.** Did the fix work, or did something else change? Re-run to confirm.
</breadcrumb>

<refuse>
## Hard Preconditions (refuse if missing)
- No repro → STOP. Cannot proceed without reproduction.
- No raw stderr → STOP. Cannot trust paraphrased errors.
- No ≥3 hypotheses → STOP. Single-anchored is bias.
- "should work" without verification → BLOCKED (CLAUDE.md §5.1 cmd 3).
- 3+ same-fail attempts → ESCALATE (CLAUDE.md §5.4 / §5.3).
</refuse>

<antidote>
## When Stuck
- **Step back HOW→WHY** (CLAUDE.md §2.8). The symptom is HOW; the cause is WHY.
- **Read the error LITERALLY.** Frustration "this SHOULD work" = misdiagnosis (ch§4.affect-table).
- **Reset assumptions.** Re-Read source, re-trace path, re-verify env. Stale memory = m17.
- **Escalate after 3-same.** No 4th creative attempt (ch§7.graduated-escalation).
- **Compound-affect (fatigue × pressure × frustration) = §17.17 cadence ×2.** Slow down, do not speed up.
</antidote>
