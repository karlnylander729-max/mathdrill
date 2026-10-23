# Concept views: understanding that feeds the drill (design)

Date: 2026-10-23 · Owner: Karl · App: `index.html` (single-file drill, live on GitHub Pages)

## Why

Karl does not engage with Anki: cards are passive (recognise, self-grade). What made a concept stick for him was the plane-normal moment:
he missed a drill question, asked for an explanation, asked a pointed follow-up about the exact step that confused him, solved a fresh
example himself, and then the drill kept handing him that question type. He has not missed it since.

His model of learning: understanding and automaticity feed each other. "If I have a good idea of what a concept is and what a question
about it is actually looking for, only then can I effectively drill it in." Concepts should feel *necessary*: emerging from several angles
of reasoning (visual, algebraic) and from what they are derived from. The loop he wants:

> get a baseline idea of a concept → drill it → if I succeed, keep drilling for automaticity → if I fail, revisit the concept → repeat.

## Goals

1. Every drill question type is linked to a **concept**. A concept is short and multi-angled, and reachable at the moment it is needed.
2. Concept learning sits **inside the drill app** (phone and laptop) and is driven by drill performance, not by a review schedule.
3. **Replace Anki completely**, pure facts (e.g. exact trig values) included. The drill's existing mechanics (main-round maintenance draws,
   rating decay, weakness weighting, mastery) take over retention.
4. Keep asking-back possible: an **Ask Claude** button hands the concept and the missed question to a Claude session.

## Non-goals

- No spaced-repetition scheduler, no flashcards, no self-grading.
- No long-form explanations in the app (Obsidian notes remain the long-form record).
- No in-app chat or AI calls (no backend; the app stays a static single file).
- No change to how drill questions are generated or checked.

## Anti-goals (would make it a failure even if it works)

- **Concepts that are too long.** Karl said this is what would make him wince. Every lens must be readable in about 30 seconds:
  a picture plus a few lines. If something needs more, it belongs to Ask Claude or the Obsidian note.
- Concepts that are generic, i.e. not in the course's notation or not grounded in the course sources.
- Anything that feels like Anki again: passive reading with nothing to do.

## What the concept view is (decided)

Layout **B, lenses**, chosen from three mockups (`.superpowers/brainstorm/concept-view-v1.html`):

- One page per **concept** (not per question type). Header: concept name, course, week, how many drill types use it.
- Four tabs:
  - **Picture**: an interactive visual the student can manipulate (e.g. drag a point X around a plane and the arrow A→X stays at 90°
    to n). This is the primary lens.
  - **Algebra**: the formula and why it has that shape, in a few lines.
  - **Origin**: what the concept is built from, with links to those earlier concepts (follow the chain backwards), and briefly what it feeds into.
  - **Try**: one fresh question generated live by one of the concept's drill types, checked on every keystroke like the drill.
- Two buttons on every tab: **Ask Claude about this** and **Back to drilling**.
- Karl said Ask Claude makes the guided step-by-step layout (option C) unnecessary.

## How Karl gets to a concept (decided)

- **Why? →** next to every miss in the results Review list (and the in-round "✗ answer" line may link to it too).
- **Concept first, in focus drills only (Karl's decision):** when a focus drill is about to show a question type whose concept Karl
  has never opened, the app shows that concept before the question. After it has been seen once, drilling runs uninterrupted; later
  visits come via Why? after a miss. The **main round never interrupts**: it stays an exam simulation. The home page instead shows
  "N concepts you haven't opened yet".
- *Claude's call:* while a concept page is open during a round, the round clock pauses; opening it is not a skip and has no rating or
  points effect.
- **Concepts list** on the home page: every concept, grouped by course, with Karl's drill accuracy on its question types, so weak
  concepts stand out (highlight concepts whose types are slipping, e.g. lost mastery or low recent accuracy).

## Ask Claude (decided)

Copies plain text to the clipboard (same mechanism as Copy for Claude): the concept's name and lenses, the question Karl just missed
(if he came via Why?), his attempt, and a one-line request to explain the step he is stuck on and to let him ask follow-ups.

## Content (decided)

- Written by Claude from the course's own sources (lecture notes, slides, problem sheets) in the course's notation, with a citation
  (file + page/section) per concept. If no source is found, mark it "standard, not yet checked against course notes".
- Must cover every question type in `TYPES`: every type maps to exactly one concept; a concept may serve several types.
  Expected scale: roughly 60–90 concepts across linear algebra, calculus, sequences & series and elementary logic, up to January.
- Facts (exact trig values, standard derivatives, Pythagorean triples…) get the same treatment: picture (e.g. unit circle, the two
  special triangles), origin, and a Try question. No bare tables.
- Length budget per lens is a hard constraint (see anti-goals); enforce it in the self-test.
- New content must be checked like drill content before it ships: the self-test renders every concept, checks every type has a
  concept, checks the length budget, and checks each Try question works.

## Calls made by Claude (Karl can override)

- **Mapping:** the app has 183 question types today. Each type maps to exactly one concept: the skill that type actually tests.
  Types that bundle several skills are rare; if one does, the concept covers the skill that decides the answer. The builder proposes
  the full type→concept mapping and shows it to Karl with the pilot.
- **Length budget (enforced by the self-test):** Algebra lens ≤ 50 words of prose plus at most 2 displayed formulas; Origin lens
  ≤ 40 words plus links to earlier concepts; Picture caption ≤ 25 words. The pilot calibrates these numbers with Karl.
- **Pictures:** every concept has a picture, built from a small set of reusable templates (unit circle, number line, function graph
  with a slider, 2D/3D vectors, truth-table/structure grid, set diagram). Where nothing natural can be manipulated, a static
  diagram is acceptable. The self-test checks that each picture renders; dragging is checked by hand in the pilot.
- **Sources and timing:** content for all weeks up to January is written now (focus drills are open ahead of lectures), from the
  KEATS-synced vault sources (sync first, per the standing rule), with citations.
- **Pilot:** about 8 concepts spread over the four courses (including the plane and exact trig), tried by Karl locally on the laptop
  (file opened in Chrome) before anything is pushed. During the pilot the "every type has a concept" self-test is relaxed; it is
  enforced for the full release.
- **Ask Claude text:** each concept carries a one-line text description of its picture for the clipboard. From the Try tab, the
  current Try question and Karl's input stand in for "the missed question"; from the Concepts list, only the concept is copied.
- **Slipping rule:** a concept's accuracy is its *worst* question type (a mean would hide a weak type); a concept is flagged when
  any of its types lost mastery or is below 70% over its last 10 answers.

## Changes outside the app (decided)

- The `/math` study skill stops creating Anki cards; what is worked out in a session becomes (or updates) a concept in the app.
  Obsidian vault notes continue as now.
- The `/review` skill and the morning plan's Anki review line are retired.
- Existing Anki decks stay in Anki untouched (nothing deleted); they stop growing.

## Constraints

- The app stays one static HTML file (no backend, no build step); CDN libraries are acceptable (math.js and KaTeX are already loaded from cdnjs).
- Must work on iPhone Safari (home-screen app) and desktop Chrome, in the existing visual style and palette.
- Seen/unseen state and anything else new lives in localStorage, per device (devices do not sync).
- Karl's coding standard (CLAUDE.md §7): YAGNI/KISS, functions ≤ 40 lines, ≤ 4 args, nesting ≤ 3, Rule of Three.
- Nothing is pushed live until Karl approves the complete change.

## Success looks like

- Karl opens concepts because they help him answer the next question, not because a schedule says so.
- A missed type, after a Why? visit and a Try, is answered correctly in later rounds (as with the plane).
- He stops needing Anki for anything.

## Left to the builder

- How the interactive pictures are built (hand-written SVG/canvas with a little JS, or a library such as JSXGraph from cdnjs),
  provided they work on a phone and stay small.
- The exact data shape of a concept in the CONFIG/TYPES area and how types reference concepts.
- How "never opened" is stored.
- Changes to the `/math` and `/review` skill files and the morning plan.
