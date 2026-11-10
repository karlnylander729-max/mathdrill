# Scratch space and open-ended rounds (design)

Agreed with Karl on 2026-11-10. Karl said "start building" before a final review, so the calls marked *(Claude's call)* are open to his override.

## Why

Some question types take several steps (row reduction, span checks, natural-deduction proofs). Doing every step in the head overloads working memory. Karl wants a place on screen to set the working out, shaped so that using it builds the habit of setting answers out the way the course does.

## Goals

- A scratch space under the question on the multi-step types. It holds working like paper. Its layout (a template per question type) teaches the course's way of setting out an answer.
- Rounds have no clock. Karl ends a round himself with an **End** button. The summary screen is the same as now.
- Speed still counts towards the rating. Par stays per question type.

## Non-goals

- The space never checks, grades or marks the working. The answer box is still the only thing that is checked.
- No phone layout work: Karl uses this on the laptop with a keyboard.
- No scratch space on one-line judgement types (subspace?, negation?, true/false).

## Question types that get a space

| Course | Type(s) | Template |
|---|---|---|
| LA | row operations, elimination, solution type, consistency (augmented matrices) | one block per step: the operation written first (`R₂ → R₂ − 2R₁`), then the new matrix below it |
| LA | in the span? | rows for the two coordinates solved, then a "check" row for the third |
| LA | dot expansion (unit vectors) | the pair grid: pair, coefficient, table value, product; then the sum |
| LA | determinants, inverses (December test and January exam) | cofactor expansion, one line per term |
| Logic | natural-deduction rule and proof types | numbered lines: line no. / formula / rule / lines used |
| Logic | truth tables (validity, tautology, counterexample, equivalence) | a table with one column per sentence letter and one per sub-formula, a row per valuation |
| Logic | formalisation | a dictionary block (P: …), then the formula |

## Decided behaviour

- The template for the type appears already laid out; Karl only fills it in.
- "Copy for Claude" and "Ask Claude" include the scratch-space content for that question, so Claude can see where it went wrong.
- Time spent in the scratch space counts as time on the question.

## Calls made by Claude

- Par for scratch-space types goes up, because writing steps takes longer than doing them in the head. Set by timing a few runs. *(Claude's call)*
- Points and personal bests stay as they are. With no clock, longer rounds score more points, so a PB rewards stamina as well as speed. *(Claude's call)*
- Build on a branch; do not push before the LA class test on 2026-11-11 09:00, so the live drill stays stable for the test. *(Claude's call)*

## Constraints

- Everything stays in `index.html`; no new dependencies.
- The self-test (`zsh scripts/selftest.sh index.html`) must print OK; it currently assumes timed rounds (`S.end`), so the clock-pause and round-timing checks need updating, not deleting.
- Laptop STACK-syntax enforcement is unchanged.

## Left to the builder

- Exact template markup (editable grid vs. monospace text area with pre-filled rows).
- How the End button sits in the play screen.
- Which existing type ids map to each template.
