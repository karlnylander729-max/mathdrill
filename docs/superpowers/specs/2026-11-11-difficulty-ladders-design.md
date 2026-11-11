# Difficulty ladders (design)

Agreed with Karl on 2026-11-11.

## Why

Karl wants drilling to stay in flow: easy enough to keep answering, hard enough to learn. Choosing between question types cannot do this alone: the app either serves types he has mastered (no learning) or types that are too hard (the round stalls, as on 2026-11-10 where one question took 2–7 minutes). So each type gets easy-to-hard levels, and the app moves him up as he becomes fluent, without him seeing it.

## Goals

- Each laddered type has 3 levels. **Level 3 is at or slightly above exam level** (Karl: "once I am at the highest level, I can be more than confident in handling exam questions"). Benchmark: the course's past papers and class tests in `<course>/sources/`. Where the current generator already reaches that bar, it becomes level 3 unchanged; where it falls short, a harder level 3 is written from the past papers and the current generator becomes level 2.
- Levels 1 and 2 are easier versions of the same skill (smaller numbers, fewer terms, fewer steps, simpler forms).
- A new type starts at level 1. It moves up when Karl is fluent at the current level and drops a level when he starts missing. All invisible: no level numbers, no settings, nothing on the home screen.
- Mastery (the existing "mastered" status) only counts answers at level 3, so mastery still means past-paper level.
- Update every course to the latest lectured week: la 6, calc 6, seq 5, logic 6 (from the KEATS sync of 2026-11-11).

## Scope (first batch)

- All 23 types in the Logic Problem Set drill.
- The newly unlocked types: calculus weeks 5–6 (limits rules, Big-O, sandwich, growth, derivatives), S&S week 5 (bounded sequences, convergence, ε–n₀, sup/inf), LA week 6 (linear map?).
- Types that have not been lectured yet get no ladder now.

## Non-goals

- No visible difficulty UI.
- No change to how types are chosen in a round (the weakness pull stays).
- No ladders for types outside the scope above in this batch.

## Calls made by Claude (Karl can override)

- **Promotion:** at the current level, 5 of the last 6 answers correct and their median time ≤ par → up one level.
- **Demotion:** 2 misses among the last 4 answers at a level → down one level (never below 1).
- **Par** stays the type's par at every level; easier levels are naturally quicker, so they promote sooner.
- Level and per-level answer log live in the existing per-type state (`drill-ratings-v1`), so they persist on each device like ratings do.
- The rating (Elo) per type is unchanged.

## Constraints

- Everything stays in `index.html`; self-test must print OK.
- Self-test fuzzes every level of every laddered type (own answer accepted, KaTeX renders, value checks).
- For each laddered type, a one-line note in the code names the past-paper question its level 3 is benchmarked against.
- Levels 1–2 must exercise the same routine as level 3, not a different skill.

## Left to the builder

- The content of levels 1 and 2 for each type (per type: what to simplify).
- How `gen` receives the level.
