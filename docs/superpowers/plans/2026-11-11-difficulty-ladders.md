# Difficulty Ladders Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Laddered question types serve level 1–3 questions, move Karl up and down invisibly, and count mastery only at level 3 (≥ exam level); every course moves to its latest lectured week.

**Architecture:** All in `index.html`. A laddered type declares `levels: 3` and `gen(L = 3)`. `draw` passes the type's current level; `record` → `applyAnswer` logs the level and runs `levelStep`. Content (Tasks 2–4) only edits generator bodies of in-scope types, so the three content tasks touch disjoint lines and can run in parallel worktrees off Task 1's commit.

**Tech Stack:** Vanilla JS in one HTML file; `zsh scripts/selftest.sh index.html`.

**Spec:** `docs/superpowers/specs/2026-11-11-difficulty-ladders-design.md`

## Global Constraints

- Level 3 ≥ exam level, benchmarked against `~/Library/Mobile Documents/com~apple~CloudDocs/v2/study/<course>/sources/` past papers / class tests / problem sheets; one comment line per laddered type: `// L3 benchmark: <file> <question>`.
- If the current generator is below exam level it becomes level 2 and a harder level 3 is written; otherwise it is level 3 unchanged.
- Levels 1–2: same routine as level 3, simpler (smaller numbers, fewer terms/steps, simpler forms).
- Promotion: 5 of the last 6 answers at the current level correct and their median time ≤ par → up. Demotion: 2 misses in the last 4 at the level → down (min 1). New laddered types start at level 1.
- Mastery counts only level-3 answers for laddered types. Rating (Elo) unchanged. No visible level UI.
- `currentWeek: { la: 6, calc: 6, seq: 5, logic: 6, basics: 4 }`.
- Self-test prints OK; no new dependencies.

## Review Focus

1. Existing localStorage state (RS entries with no `lvl`/`llog`, log entries with no `l`) must load without errors; laddered types start at level 1, unladdered types behave exactly as before.
2. A demotion right after a promotion must not loop: the level log resets on every level change.
3. Concept "Try" tab and other `t.gen()` callers without a level get level 3 (exam level), never undefined behaviour.
4. Skipped and resurfaced questions keep the level they were drawn at.
5. A laddered type whose level-1 generator returns null too often still draws (≥ 30/100 accepted per level).

---

### Task 1: Ladder engine and weeks

**Files:** Modify `index.html`: CONFIG (`currentWeek`, `ladder: { up: [5, 6], down: [2, 4] }`), `draw`, `record`, `applyAnswer`, `masteryStatus` caller, `generatorTests`; new `ladderTests()` wired into `out.ok`; `scripts/selftest.sh` prints `LADDER` lines.

**Interfaces — Produces:**
- `isLaddered(type): boolean` (`type.levels === 3`)
- `levelOf(typeId): 1|2|3` (laddered: `RS[id]?.lvl ?? 1`; else 3)
- `levelStep(st, ok, ms, par): 'up'|'down'|null` — mutates `st.lvl`, `st.llog` (last answers at the current level, reset on change)
- questions carry `q.level`; log entries `{ d, ok, ms, l }`
- `generatorTests` reports laddered types as `<id>@<L>` rows

- [ ] **Step 1: Write `ladderTests()`** using a fixture laddered type `{ id: 'fxL', levels: 3, par: 10, gen: L => ({ q: `L${L}`, a: String(L), kind: 'num' }) }` pushed into `TYPES`/`TYPE_BY_ID` for the test: new type → `levelOf('fxL') === 1`; 5 fast correct at level 1 → level 2; then misses ok,✗,ok,✗ → level 1; a promotion empties `llog`; `draw` on a drill of only `fxL` yields `q.level === levelOf('fxL')` and `q.q === 'L' + level`; masteryStatus input for a laddered type excludes non-level-3 entries (30 correct fast level-2 answers → not mastered); an RS entry without `lvl`/`llog` loads and steps without throwing; `currentWeek` equals the Global Constraints value.
- [ ] **Step 2: Run** `zsh scripts/selftest.sh index.html` → FAIL (`ladderTests`/`levelOf` undefined).
- [ ] **Step 3: Implement** the Produces list; `draw` calls `type.gen(levelOf(type.id))` and sets `q.level`; resurfaced questions keep their object (so their level); `applyAnswer(type, ok, ms, level)` appends `l` and calls `levelStep` for laddered types; mastery for laddered types filters `l === 3`; `generatorTests` fuzzes each level (100 draws, ≥ 30 accepted).
- [ ] **Step 4: Run** → OK.
- [ ] **Step 5: Commit** `Ladder engine: levels per type, invisible promotion and demotion; weeks la 6 calc 6 seq 5 logic 6`.

### Task 2: Logic ladders (23 types)

**Files:** Modify `index.html`: generator bodies of the 23 `ps-logic` drill types only. **Consumes:** Task 1 (`levels: 3`, `gen(L = 3)`).
Benchmark: `elementary-logic/sources/` Jan exams 2021–25 P1, mock 2025-26, Book of Problems.

- [ ] **Step 1:** For each type, read its generator and the benchmark; record in the comment whether the current generator is L3 or L2.
- [ ] **Step 2:** Add `levels: 3`, `gen(L = 3)` with L1/L2 (and a new L3 where needed).
- [ ] **Step 3: Run** the self-test → OK, with every `<id>@1..3` row free of errors.
- [ ] **Step 4: Commit** `Logic ladders`.

### Task 3: Calculus ladders (weeks 5–6 types)

Same shape as Task 2 for: `calc-bigo`, `calc-growth`, `calc-limtrick`, `calc-squeeze`, `calc-dstd`, `calc-dstd2`, `calc-dchain`, `calc-chain2`, `calc-dprod`, `calc-deriv`, `calc-logdiff`, and `calc-quot` if it exists. Benchmark: `calculus-1/sources/` Exercises 4–6, `Class Test 1 2026 Solutions.pdf`, worked examples in `Calculus_1_2026-27.pdf`. Commit `Calculus ladders`.

### Task 4: S&S and LA ladders

Same shape for `seq-bddseq`, `seq-convdiv`, `seq-epsdist`, `seq-n0`, `seq-supinf`, and `la-linmap`. Benchmark: `sequences-and-series/sources/` Exercises 3–6 and past class tests; `linear-algebra/sources/` ProblemSet6 and the 2023/24–2025/26 CT2 linear-map questions. Commit `S&S and LA ladders`.
