# Concept Views Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add short, multi-lens concept views to the drill app, reachable from misses, a Concepts list and concept-first in focus drills, replacing Anki as Karl's way of absorbing concepts.

**Architecture:** Everything stays in the single file `index.html`. A new `CONCEPTS` block (after `TYPES`) holds content; a `CONCEPT_OF` index maps each type id to one concept. A new `concept` screen renders four tabs (Picture / Algebra / Origin / Try) using a few reusable SVG picture templates. Self-test functions in the existing `#test` harness enforce coverage, length budgets and rendering. Pilot (8 concepts, local only) gates the full rollout.

**Tech Stack:** Vanilla JS, inline SVG + pointer events (no new library), KaTeX + math.js (already loaded from cdnjs), localStorage, headless Chrome for the self-test.

**Spec:** `docs/superpowers/specs/2026-10-23-concept-views-design.md`

## Global Constraints

- One static HTML file; no backend, no build step; no new CDN libraries (pictures are hand-written SVG).
- Existing visual style and palette (`--bg #14161a`, `--panel #1d2026`, `--accent #6ea8fe`, `--good`, `--bad`, key bg `#262a32`).
- Must work in iPhone Safari (home-screen app) and desktop Chrome; touch and mouse dragging on pictures.
- Length budget (self-test enforced): Algebra ≤ 50 words of prose + ≤ 2 display formulas; Origin ≤ 40 words + links; Picture caption ≤ 25 words.
- Every concept cites its course source (file + page/section) or is marked `standard, not yet checked against course notes`.
- Concept-first only in focus drills; the main round never shows a concept unprompted.
- While a concept is open during a round, the round clock pauses; opening it is not a skip and changes no rating or points.
- New state in localStorage only: key `drill-concepts-seen-v1` (array of concept ids).
- Coding standard (CLAUDE.md §7): functions ≤ 40 lines (target 25), ≤ 4 args, nesting ≤ 3; Rule of Three.
- Nothing is pushed to GitHub until Karl approves the complete change (pilot is tried locally via `file://`).

## Review Focus

1. **Phone width (375 px):** tabs, picture and Try input must fit without horizontal scroll; dragging must work with a finger (pointer events, `touch-action: none` on the SVG). → test in Task 2 (`pictureFitsTest`) and Task 3 (layout check in screenshot step).
2. **Round ends while a concept is open:** the paused clock must not expire behind the concept; returning resumes with the remaining time. → test in Task 3 (`pauseResumeTest`).
3. **First run on a new device:** every concept is unseen, so concept-first must show each concept at most once (two types sharing a concept → one interruption). → test in Task 4 (`conceptFirstOnceTest`).
4. **Try tab with every answer kind:** bool buttons, `noKeyboard` key rows, `mat`/`vec`/`set` answers must all work inside the concept screen. → test in Task 3 (`tryKindsTest`).
5. **Clipboard unavailable (iOS permissions):** Ask Claude must fall back to the textarea copy used by Copy for Claude. → test in Task 5 (`askClaudeTextTest`, plus manual check in pilot).

---

### Task 1: Concept registry, test runner script and self-test checks

**Files:**
- Modify: `index.html` (add `CONCEPTS` block after `TYPES` closes; add checks to the SELF-TEST script)
- Create: `scripts/selftest.sh` (copy of the `/tmp/drilltest.sh` runner, made permanent; prints `OK`/`FAIL` and `!!` lines)

**Interfaces:**
- Produces:
  - `CONCEPTS: Array<Concept>` where `Concept = { id: string, name: string, cat: 'la'|'calc'|'seq'|'logic'|'basics', week: number, source: string, types: string[], origin: string[] /* concept ids */, feeds: string[], picture: { template: string, params: object, caption: string, alt: string }, algebra: string /* text with $TeX$ */, originText: string }`
  - `CONCEPT_OF: Record<typeId, conceptId>` built from `CONCEPTS[].types`
  - `CONFIG.conceptCoverage: 'pilot' | 'full'` (start at `'pilot'`)
  - `conceptTests(): Array<failure>` added to `runSelfTest()`'s `ok`.

- [ ] **Step 1: Write the failing tests** — `conceptTests()` returns failures for: a type listed in two concepts; an `origin`/`feeds` id that is not a concept; `wordCount(stripTeX(algebra)) > 50` or more than 2 `$$…$$`/display formulas; `wordCount(originText) > 40`; `wordCount(picture.caption) > 25`; empty `source`; when `conceptCoverage === 'full'`, any id in `TYPES` (hub or not) without a concept. Add two fixture concepts inside the test (one valid, one 60-word algebra) and assert exactly the expected failure.
- [ ] **Step 2: Run** `scripts/selftest.sh index.html` → Expected: `FAIL` with `conceptTests is not defined`.
- [ ] **Step 3: Implement** `wordCount(s: string): number`, `stripTeX(s: string): string` (drops `$…$` spans), the `CONCEPTS` array (empty for now), `CONCEPT_OF`, `CONFIG.conceptCoverage = 'pilot'`, and `conceptTests()`; wire it into `out.ok`.
- [ ] **Step 4: Run** `scripts/selftest.sh index.html` → Expected: `OK`.
- [ ] **Step 5: Commit** `git commit -am "Concept registry and self-test checks"` (also `git add scripts/selftest.sh`).

### Task 2: Picture templates

**Files:**
- Modify: `index.html` (new `PICTURES` section between HELPERS and CHECKER)

**Interfaces:**
- Consumes: `Concept.picture` from Task 1.
- Produces: `PICTURES: Record<template, (svgEl: SVGSVGElement, params: object) => void>` with templates `unitCircle`, `numberLine`, `graphSlider`, `vectors2d`, `plane3d`, `truthGrid`, `setDiagram`; `renderPicture(container: HTMLElement, picture): void` (creates a 320×220 viewBox SVG with `touch-action: none`, calls the template, appends the caption).
- Pure geometry helpers tested on their own: `planePoint(params, u, v) -> [x,y,z]`, `unitCirclePoint(m) -> {x, y, exactCos, exactSin}` (reuse `exact()`), `numberLineInterval(spec) -> {lo, hi, lc, hc}`.

- [ ] **Step 1: Write the failing tests** — `pictureTests()`: for each template, `renderPicture` on a detached div produces an `<svg>` with ≥ 1 child and no thrown error; `unitCirclePoint(2)` gives `exactCos '√3/2'`, `exactSin '1/2'`; `planePoint({n:[1,3,-2], a:[0,0,1]}, 1, 2)` satisfies `n·X = n·a` within 1e-9; `pictureFitsTest`: every SVG has `viewBox` width 320 and CSS `max-width: 100%`.
- [ ] **Step 2: Run** `scripts/selftest.sh index.html` → Expected: `FAIL` (`renderPicture is not defined`).
- [ ] **Step 3: Implement** the seven templates with pointer-event dragging (pointerdown/move/up on the SVG; update via the pure helpers), and `renderPicture`.
- [ ] **Step 4: Run** `scripts/selftest.sh index.html` → Expected: `OK`.
- [ ] **Step 5: Commit** `git commit -am "Concept picture templates"`.

### Task 3: Concept screen (tabs, Try, clock pause)

**Files:**
- Modify: `index.html` (new `<div id="concept" class="screen">`, CSS for `.tabs`, app functions)

**Interfaces:**
- Consumes: `CONCEPTS`, `CONCEPT_OF` (Task 1), `renderPicture` (Task 2), existing `draw`/`check`/`renderMath`/`setKeys`.
- Produces: `openConcept(conceptId: string, context?: { q?: object, attempt?: string }): void`, `closeConcept(): void` (returns to the previous screen), `markSeen(conceptId): void`, `seenConcepts(): Set<string>` (localStorage `drill-concepts-seen-v1`).

- [ ] **Step 1: Write the failing tests** — `conceptScreenTests()` with a fixture concept: `openConcept` shows the `concept` screen with 4 tabs labelled `Picture`, `Algebra`, `Origin`, `Try`; Origin lists one link per `origin` id; `markSeen` persists across a reload of `seenConcepts()`; **`pauseResumeTest`**: start a round, record `left = S.end - now`, open a concept, advance the fake clock 30 s, close → `S.end - now` equals `left` ± 250 ms and `S.log` is unchanged; **`tryKindsTest`**: for one type of each kind present in `TYPES` (`num, expr, vec, mat, interval, text, set, logic, syntax, bool`), the Try tab draws a question from that type and `check(q, answerInput(q), false)` accepts its own answer through the Try input path (bool via the Try buttons).
- [ ] **Step 2: Run** `scripts/selftest.sh index.html` → Expected: `FAIL`.
- [ ] **Step 3: Implement** the screen: header (name, course label, week, `n drill types`), tabs, Picture via `renderPicture`, Algebra via `renderMath`, Origin text plus links (`openConcept(id)`), Try (draw from a random type of the concept; on correct show "✓ — back to drilling" and mark seen), buttons `Ask Claude about this` and `Back to drilling`. Clock: on open during a round store `S.pausedAt = Date.now()` and `clearInterval(S.timer)`; on close add `Date.now() - S.pausedAt` to `S.end` and to `S.start`, restart the timer.
- [ ] **Step 4: Run** `scripts/selftest.sh index.html` → Expected: `OK`. Screenshot the concept screen at 500×900 (headless) with a fixture concept and check: no horizontal overflow, tabs on one line.
- [ ] **Step 5: Commit** `git commit -am "Concept screen with lenses, Try and clock pause"`.

### Task 4: Entry points — Why?, concept-first in focus drills, Concepts list

**Files:**
- Modify: `index.html` (`reviewList`, `feedback` prev line, `nextQuestion`, `showHome`, new `conceptsList`)

**Interfaces:**
- Consumes: Task 1 registry, Task 3 `openConcept`/`seenConcepts`, existing `RS` ratings state and `masteryStatus`.
- Produces: `conceptAccuracy(conceptId): { worstType: string|null, acc: number|null, slipping: boolean }` (worst type over its last 10 answers; `slipping` = any type lost mastery or acc < 0.70 over its last 10 answers); `unopenedCount(): number` (active-in-main-round concepts not in `seenConcepts()`).

- [ ] **Step 1: Write the failing tests** — `entryTests()`: `reviewList` HTML for a missed type with a concept contains a `Why?` link calling `openConcept('<id>'`; a type without a concept shows no link; **`conceptFirstOnceTest`**: in a focus drill whose two types share one unseen concept, drawing both types opens the concept once (count `openConcept` calls via a spy) and never in a main round (`S.drill === null`); `conceptAccuracy` on fixture logs: 10 answers with 6 correct → `acc 0.6, slipping true`; mastered type then a miss that drops mastery → `slipping true`; `unopenedCount()` equals active concepts minus seen.
- [ ] **Step 2: Run** `scripts/selftest.sh index.html` → Expected: `FAIL`.
- [ ] **Step 3: Implement** the `Why? →` link in `reviewList` and the in-round `✗ answer` line; in `nextQuestion`, when `S.drill` is set and `CONCEPT_OF[q.type]` is unseen, call `openConcept` before showing the question; home: "N concepts you haven't opened yet" line and a collapsible **Concepts** section grouped by course (same `details.cat` style), each row = name, worst-type accuracy, a `slipping` badge.
- [ ] **Step 4: Run** `scripts/selftest.sh index.html` → Expected: `OK`.
- [ ] **Step 5: Commit** `git commit -am "Why? links, concept-first in focus drills, Concepts list"`.

### Task 5: Ask Claude text

**Files:**
- Modify: `index.html`

**Interfaces:**
- Consumes: Task 3 `openConcept` context, existing `plain`, `copySummary` fallback approach.
- Produces: `conceptAskText(concept, context?: { q?: object, attempt?: string }): string`; `askClaude(): Promise<void>` (clipboard with textarea fallback; button text `Copied ✓ · paste into Claude`).

- [ ] **Step 1: Write the failing test** — **`askClaudeTextTest`**: text contains the concept name, the picture `alt`, the algebra with `$…$` kept, the origin text, and — when context has a missed question — `Q:` with the question and `I had typed: "<attempt>"`; from the Concepts list (no context) it contains no `Q:` line; it ends with the request line `Explain the step I'm stuck on, then let me ask follow-ups.`
- [ ] **Step 2: Run** → Expected: `FAIL`.
- [ ] **Step 3: Implement** `conceptAskText` and `askClaude` (from the Try tab, context = the current Try question and input).
- [ ] **Step 4: Run** → Expected: `OK`.
- [ ] **Step 5: Commit** `git commit -am "Ask Claude from concepts"`.

### Task 6: Pilot content (8 concepts) and local trial — STOP for Karl's feedback

**Files:**
- Modify: `index.html` (`CONCEPTS` entries)

**Interfaces:**
- Consumes: Tasks 1–5.

Pilot concepts (sync KEATS for the four courses first, per the standing rule; cite sources):
1. `plane-point-normal` (la; types `la-plane-d`; picture `plane3d`)
2. `matrix-product-entry` (la; `la-rowcol`, `la-entry`, `la-product`, `la-product23`, `la-Av`, `la-size`; picture `vectors2d` row·column)
3. `exact-trig` (calc; `calc-trig`; picture `unitCircle`)
4. `inverse-trig-range` (calc; `calc-arc`, `calc-arc-branch`; picture `unitCircle`)
5. `rational-limit-infinity` (calc; `calc-lim-inf`; picture `graphSlider`)
6. `counting-integers` (seq; `seq-terms`, `seq-const`, `seq-count`; picture `numberLine`)
7. `modulus-interval` (seq; `seq-modulus`, `seq-modeq`; picture `numberLine`)
8. `bracket-conventions` (logic; `logic-main`, `logic-restore`, `logic-drop`, `logic-official`, `logic-sentence`; picture `truthGrid` tree/scope view)

- [ ] **Step 1:** Write the 8 concepts within the length budget; run `scripts/selftest.sh index.html` → Expected: `OK`.
- [ ] **Step 2:** Open `index.html` locally in Chrome (`open -a "Google Chrome" index.html`) and drive: home Concepts list, a focus drill with an unseen pilot concept (concept-first), a miss → `Why?`, Try, Ask Claude, Back. Screenshot each.
- [ ] **Step 3:** Commit `git commit -am "Pilot concepts (8)"`. **Do not push.** Hand to Karl to try locally; collect feedback on length, pictures, flow. Adjust budgets/templates from feedback before Task 7.

### Task 7: Full content (all types → concepts)

**Files:**
- Modify: `index.html` (`CONCEPTS`), set `CONFIG.conceptCoverage = 'full'`

- [ ] **Step 1:** Propose the full type→concept mapping for all types in `TYPES` (one concept per type, grouped by course) and show it to Karl; apply his changes.
- [ ] **Step 2:** Write the concepts per course (may run as four parallel builders on copies, like the atom build, each passing `scripts/selftest.sh` before merge), from synced sources with citations.
- [ ] **Step 3:** Set `CONFIG.conceptCoverage = 'full'`; run `scripts/selftest.sh index.html` → Expected: `OK` (no uncovered types).
- [ ] **Step 4:** Spot-check samples of each course's concepts by hand (content correct, in course notation, within budget). Commit `git commit -am "Concepts for all question types"`.

### Task 8: Retire Anki in the study workflow

**Files:**
- Modify: `~/.claude/skills/math/SKILL.md` (concept loop step 9 and practice step 6: produce/update an app concept instead of Anki cards; keep the Obsidian note)
- Modify: `~/claude-projects/study/schedule.py:228` (remove the `- review · … Study card(s) due` morning-plan line; keep the rest)
- Modify: `~/.claude/skills/review/SKILL.md` (mark retired: one line saying the drill app replaces it; existing Study::* decks untouched)

- [ ] **Step 1:** In `~/claude-projects/study`, run its tests (`uv run pytest -q` if present) → note the baseline.
- [ ] **Step 2:** Edit `schedule.py` to drop the review line; adjust the test that expects it; run tests → Expected: pass.
- [ ] **Step 3:** Edit the two skill files as above (no deletion of decks, no deletion of the review script).
- [ ] **Step 4:** Commit in each repo that is under git (`~/claude-projects/study`, `~/projects/mathdrill`), message `Retire Anki: concepts live in the drill app`.

### Task 9: Release

- [ ] **Step 1:** `scripts/selftest.sh index.html` → `OK`; screenshot home, concept screen, review with Why? at phone width.
- [ ] **Step 2:** Show Karl the summary and ask for push confirmation (Tier 2). On yes: `git push`, wait for the Pages build, run the self-test against the live URL → `OK`.
