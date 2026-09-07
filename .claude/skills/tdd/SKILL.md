---
name: tdd
description: Red-green-refactor workflow for MeowPay's backend and mobile code. Consult before writing any new business logic (transfers, balances, validation) - not for trivial changes like copy edits or config tweaks.
---

# TDD in this repo

Applies to logic that can be wrong: transfer rules, balance math, validation, state transitions.
Doesn't apply to copy edits, styling, config, or scaffolding - don't force a test-first ritual on
changes that have no behavior to get wrong.

In practice here, this cycle is what the `tdd-coder` agent executes for a given piece of work,
against a plan `tdd-planner` produced - see `.claude/agents/`. This file is the workflow contract
those two agents (and any human) follow; it doesn't change based on who's driving.

## The cycle

1. **Red** - write a test for the behavior you're about to add. Run it. Confirm it fails, and
   fails for the *reason you expect* (not a compile error, not the wrong assertion). A red test
   you haven't actually watched fail isn't proof of anything.
2. **Green** - write the minimum code to pass it. Not the eventual "proper" version - the
   smallest thing that makes the test pass.
3. **Refactor** - clean up with the test still green. Rerun after every change, not just at the end.

## Per stack

**Backend (Kotlin/JUnit5)** - new logic in `service/` gets a test in the matching
`backend/src/test/kotlin/.../service/` class, run against real Postgres via Testcontainers
(`@Import(TestcontainersConfig::class)`) - not H2, not a mocked repository. Self-contained
fixtures (a `newCatWithBalance`-style helper), not reliance on the Flyway seed data, so tests
don't depend on execution order.

```bash
cd backend
./gradlew test --tests "*YourNewTest*"   # confirm red
# implement
./gradlew test --tests "*YourNewTest*"   # confirm green
./gradlew test                            # confirm nothing else broke
```

If the change touches locking/concurrency, red-green isn't enough on its own - a test that only
exercises the happy path won't catch a race. A concurrency test needs multiple threads and an
assertion on the invariant that must hold regardless of interleaving - not just "no exception was
thrown."

**Mobile domain/use-cases (Dart)** - test against a fake repository (no widget pump, no backend):

```bash
cd mobile
flutter test test/presentation/your_test.dart   # confirm red
# implement
flutter test                                     # confirm green, nothing else broke
```

**Mobile Cubit (state management)** - use `bloc_test`'s `blocTest()` to assert the exact sequence
of emitted states *before* writing the Cubit method that produces them.

**Web (Next.js)** - **no test runner is wired up** (just `next dev`/`build`/`lint`). TDD in the
literal red-green sense isn't possible here yet. Until that changes, the closest equivalent is:
`npm run build` (type errors) + `npx eslint .` (lint) + an actual manual check in the Browser pane
before considering a web change done - don't skip the manual check just because the other two are
green. If a web change is complex enough that you want real TDD for it, say so explicitly rather
than silently treating lint-clean as "tested" - adding a test runner is a real decision (which
one, config, CI impact) that shouldn't happen implicitly as a side effect of one feature.

## If the full-suite run turns something red

The `./gradlew test` / `flutter test` (full, not scoped) step above is not a formality — it's
where you find out whether your change broke an existing use case. If it does:

- **Default response: fix your change**, not the test. An existing test going red almost always
  means the change regressed something, not that the test was wrong.
- Only touch an existing test's expectations if the *user* explicitly confirmed that behavior
  should change — never decide that unilaterally and edit/delete the test to get back to green.
  See `CLAUDE.md`'s "No regressions without explicit sign-off" for the full rule.
- If you're not sure whether a failing test represents a real regression or a legitimately
  outdated expectation, that uncertainty is itself the reason to stop and ask, not to guess.

## What this buys, honestly

A red test you never watched fail can pass for the wrong reason (testing nothing, or testing a
mistake in the test itself). The discipline here isn't "write tests" - it's "watch the test fail
first," which is the part that's easy to skip and is where most of the actual value is.
