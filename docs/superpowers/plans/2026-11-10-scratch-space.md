# Scratch Space and Open-Ended Rounds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rounds run until Karl presses End, and multi-step LA/logic types show a pre-filled working space whose content travels with "Copy for Claude" and "Ask Claude".

**Architecture:** All in `index.html`. The round clock becomes an elapsed clock (`S.t0`) that never ends the round. A `SCRATCH` map (type id → template function) drives a `<textarea id="scratch">` on the play screen; the edited text is stored on the log entry as `work`.

**Tech Stack:** Vanilla JS in one HTML file; self-test via `zsh scripts/selftest.sh index.html`.

**Spec:** `docs/superpowers/specs/2026-11-10-scratch-space-design.md`

## Global Constraints

- No new dependencies; everything stays in `index.html`.
- The space never checks or grades working; only the answer box is checked.
- Speed still counts; par stays per type. Scratch types: `par × CONFIG.scratchParFactor` with `scratchParFactor: 2` (Claude's call, retune after real runs).
- Summary screen unchanged; End button ends the round.
- Self-test must print `OK`. Do not push before 2026-11-11 10:00 (LA class test).

## Review Focus

1. Concept pause/resume mid-round: the elapsed clock and the question clock must both pause (existing `pauseResumeTest`, rewritten for `S.t0`).
2. Untouched template: a question answered without editing the space must not add a "My working" block to the summary.
3. Bool scratch types (e.g. `logic-valid`): answer buttons still work while the textarea has focus; Enter in the textarea must not submit.
4. Round left open for a long time: tick keeps running, never calls `endRound` (test advances the fake clock 10 minutes).
5. The pending (unanswered) question at End includes its working.

---

### Task 1: Open-ended rounds

**Files:** Modify `index.html`: CONFIG (`roundSeconds` removed), `startRound`, `fillCurve`, `tick`, `resumeRound`, play-screen `#timer`; tests `pauseResumeTest`, `lastAnswerDrillRun`, `roundEndTest`.

**Interfaces:** Produces `S.t0: number` (round start, shifted by pauses) and `elapsedSec(): number`.

- [ ] **Step 1: Rewrite the tests.** `roundEndTest` → advance a fake `Date.now` by 600 000 ms, call `tick()`; expect `S !== null`; then `endRound()` → results screen on. `pauseResumeTest` → `elapsed = now - S.t0` unchanged (±250 ms) across a 30 s concept visit. `lastAnswerDrillRun` → `record(true)` then `endRound()`; expect results screen and no concept opened.
- [ ] **Step 2: Run** `zsh scripts/selftest.sh index.html` → expected FAIL (round still ends at 120 s).
- [ ] **Step 3: Implement.** `S.t0 = Date.now()` replaces `S.end`; `elapsedSec = () => Math.floor((Date.now() - S.t0) / 1000)`; `fillCurve` fills up to `elapsedSec()`; `tick` shows `m:ss` elapsed in `#timer` and never ends the round; `resumeRound` adds the pause to `S.t0` and `S.start`.
- [ ] **Step 4: Run** the self-test → `OK`.
- [ ] **Step 5: Commit** `Open-ended rounds: elapsed clock, End button ends the round`.

### Task 2: Scratch templates and the working space

**Files:** Modify `index.html`: play-screen markup (`<textarea id="scratch">` after `#prompt`), `SCRATCH` map + `scratchTemplate(q)` near the RATING section, `nextQuestion`, `onInput`/keyboard handling, par adjustment after `TYPES`; new test `scratchTests()` wired into `out.ok`.

**Interfaces:** Produces `SCRATCH: {[typeId]: (q) => string}`, `scratchTemplate(q): string | null`, `scratchWork(): string` (current text if edited from the template, else `''`).

Templates (text, monospace): row ops/augmented (`la-rowop`, `la-elimk`, `la-elementary`, `la-soltype`, `la-consist`, `la-freevars`): one block per step, op line then new rows, plus "last row reads: 0 = ___"; span (`la-inspan`): two solve rows + check row; dot expansion (`la-dotexp`): pair | coeff | value | product grid + sum; determinants/inverses (`la-det3`, `la-cof3`, `la-invcof`, `la-detrowops`): expansion along ___, three signed terms, det; ND (`logic-ndrule`, `logic-goalrule`, `logic-ndassume`, `logic-ndrule2`, `logic-quantlegal`): `# | formula | rule | from` with premise lines; truth tables (`logic-valid`, `logic-taut`, `logic-counter`, `logic-equiv`, `logic-consistent`, `logic-column`, `logic-forced`, `logic-truerows`): header from the sentence letters in `q.q`, one row per valuation (max 3 letters → 8 rows); formalisation (`logic-formalise`, `logic-l2formal`): dictionary block + formula line.

- [ ] **Step 1: Write `scratchTests()`.** Every `SCRATCH` key is a `TYPE_BY_ID` id; for each, 20 draws give a non-empty template; a truth-table template for a 2-letter question has 4 valuation rows; after `queueTypes(['la-inspan'])` + `nextQuestion()` the textarea is visible and holds the template, after `queueTypes(['la-dot'])` it is hidden; Enter inside the textarea does not call `record`; scratch types have `par` doubled vs `BASE_PAR`.
- [ ] **Step 2: Run** the self-test → FAIL (`scratchTests is not defined`).
- [ ] **Step 3: Implement** the map, the textarea (show + fill in `nextQuestion`, hide otherwise; `rows` sized to the template), `BASE_PAR` snapshot and the par multiplication.
- [ ] **Step 4: Run** → `OK`. Screenshot the play screen at 1280×900 on an `la-inspan` and a `logic-valid` question: textarea below the prompt, answer box still reachable.
- [ ] **Step 5: Commit** `Scratch space with course-style templates on multi-step types`.

### Task 3: Working travels with Copy for Claude and Ask Claude

**Files:** Modify `index.html`: `record` (log `work`), `endRound` pending entry, `questionLine`, `feedback` (`WHY_PREV.work`), `conceptAskText`; extend the existing summary test.

- [ ] **Step 1: Extend tests.** In the summary test add a log entry with `work: 'R2 → R2 − 2R1\n(0, 1 | 3)'`; expect the text to contain `My working:` and `R2 → R2 − 2R1`; an entry with `work: ''` adds no `My working:`. `conceptAskText(c, { q, attempt: '1', work: 'x' })` contains `My working:\nx`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement** `work: scratchWork()` in `record` and the pending entry; `questionLine` appends `\n   My working:\n` + indented lines when `e.work`; `conceptAskText` appends the same block.
- [ ] **Step 4: Run** → `OK`.
- [ ] **Step 5: Commit** `Include scratch working in Copy for Claude and Ask Claude`.
