# MeowPay (slice)

A thin, real, end-to-end slice of a fintech: one cat sends treats to another. This file is
written **before any application code exists** - it's the contract this build follows, not a
retrospective description of one. See [README.md](README.md) once it exists for the pitch aimed
at a human reader; this file is for a Claude Code session picking up the codebase mid-build.

## Why this file comes first

A sibling project (`meowpay`, same brief, same author) was built the usual way: app first, then
`CLAUDE.md`/skills/an agent added partway through once the need for them became obvious. That
worked, but it meant the first ~20 commits had no persistent context or enforced workflow behind
them. This repo inverts the order on purpose: the workflow contract and the two agents that
execute it exist before a single line of `backend/`, `web/`, or `mobile/` code is written, so
*every* commit that follows is made under it, not just the later ones.

## Structure and scope

```
backend/   Kotlin + Spring Boot REST API, Postgres, Flyway     <- the actual submission,
web/       Next.js (App Router, TS) frontend                    <- with web/, per the brief
mobile/    Flutter (Android + iOS), Clean Architecture + Cubit   <- explicitly OUTSIDE "the slice"
```

**`mobile/` is scope creep, on purpose, clearly labeled.** The brief asks for one thin slice and
caps effort at roughly half a day; a third client on two more platforms doesn't make the transfer
logic more correct. Don't let `mobile/`'s presence pull `backend/`/`web/` decisions toward "we
need this to work on three platforms" - they only ever need to serve one web frontend.

Unlike the sibling project, mobile state management here is **Cubit from the start**, not an
MVVM `ChangeNotifier` ViewModel later swapped for Cubit. That swap was a genuine, worthwhile
architectural exploration the first time; repeating it here on a second attempt at the same app
would be manufactured, not organic - we already know which one we'd land on. See
[Decisions and trade-offs](#decisions-and-trade-offs) once written for the reasoning, carried
over rather than re-derived.

## Development workflow - read before writing code

This repo has two agents specifically so this section is followed, not just aspirational. The
split is deliberate: **planning and implementing are different passes, done by different
agents**, so a plan can't quietly skip straight to code before anyone's checked it against the
architecture rules.

- **`.claude/skills/run/`** - how to launch each piece and *verify* it's serving real traffic,
  not just that a command exited 0.
- **`.claude/skills/tdd/`** - the red-green-refactor workflow for this codebase, per stack,
  including the honest caveat that `web/` has no test runner so literal TDD isn't possible there.
- **`.claude/agents/tdd-planner.md`** - read-only (`Read`/`Grep`/`Glob`/`Bash`, no `Edit`/`Write`).
  Reads the above plus this file's architecture/testability sections and whatever code already
  exists near the change, then returns a concrete test-first plan: which layers change, the
  first failing test in concrete terms, what "green" looks like, what's deliberately not
  covered, and named regression risk. It never writes code.
- **`.claude/agents/tdd-coder.md`** - has `Write`/`Edit`/`Bash`. Takes a `tdd-planner` plan (or a
  small, fully-specified trivial change that doesn't need one) and actually executes red-green-
  refactor: writes the failing test, confirms it fails for the right reason, writes the minimal
  code to pass it, then runs the **full** existing suite for that stack to check for regressions.
  It reports back what changed and the verification result - it never commits.

**Before implementing any non-trivial backend, mobile, or web logic change: `tdd-planner` first,
then `tdd-coder` against that plan, then the orchestrating session reviews the result and commits
it.** "Non-trivial" means anything with behavior that can be wrong - transfer rules, balance
math, validation, state transitions; trivial copy/config/styling edits can go straight to
`tdd-coder` (or be done directly) without a planning pass.

### No regressions without explicit sign-off

Before considering *any* change done, run the **full** existing test suite for whatever you
touched - not just the new test for the new behavior:

```bash
./gradlew test                              # backend - all of it, not just --tests "*YourThing*"
flutter analyze && flutter test              # mobile - all of it
npm run build && npx eslint .                # web - closest equivalent given no test runner
```

If something that passed before your change now fails or behaves differently, that's a
regression, and there are exactly two acceptable responses:

1. **Fix your change** so the existing behavior still holds - this is the default, correct
   response almost every time.
2. **Stop and ask the user** if you believe the existing behavior is actually what needs to
   change. Say what would change and why, and get an explicit yes before touching it.

What's **not** acceptable: quietly editing, weakening, or deleting an existing test to make a
regression go away, or rationalizing "well, the old behavior was arguably wrong anyway" without
asking first. This applies to `tdd-coder` mid-implementation exactly as much as to a human.

## Seeded data (planned - used everywhere once it exists: tests, demos, this file)

Flyway migration `V2__seed_cats.sql` seeds three cats with deliberately readable fake UUIDs:

| Cat      | ID                                       | Starting balance |
|----------|-------------------------------------------|-------------------|
| Whiskers | `11111111-1111-1111-1111-111111111111`    | 100               |
| Mochi    | `22222222-2222-2222-2222-222222222222`    | 50                |
| Biscuit  | `33333333-3333-3333-3333-333333333333`    | 0                 |

Same fictional cats/balances as the sibling `meowpay` repo - it's the same fictional product
spec, so there's no reason to invent different fixture data.

## Harness / environment

Facts about *this machine*, true regardless of which repo is being built - carried over from the
sibling project rather than re-discovered by trial and error:

- **JDK**: Gradle's toolchain auto-provisioning (`org.gradle.toolchains.foojay-resolver-convention`
  in `backend/settings.gradle.kts`) fetches a JDK itself - no local JDK install required.
- **Docker**: this machine runs [Colima](https://github.com/abiosoft/colima), which needs two env
  vars Docker Desktop doesn't:
  ```bash
  export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
  export TESTCONTAINERS_RYUK_DISABLED=true
  ```
  (Ryuk, Testcontainers' cleanup sidecar, fails to start against Colima's VM networking.)
- **Flutter**: SDK 3.41.4 / Dart 3.11.1. `mobile/android/gradle/wrapper/gradle-wrapper.properties`
  needs Gradle 9.1.0 (not the scaffold's default 8.14) - 8.14 can't run under a JDK newer than 24,
  and this machine's JDK is newer than that.
- **Android emulator**: reaches the host Mac at `10.0.2.2`, not `localhost`. iOS Simulator shares
  the host's network stack, so it doesn't have this problem.
- **iOS Simulator / Xcode**: needs [CocoaPods](https://cocoapods.org) (`brew install cocoapods`) -
  Flutter's iOS build generates a `Podfile` even for a plugin-free app.
- **Spring Boot 4** (assume this is what gets scaffolded - it's the current default as of this
  writing): dependency starters are renamed (`spring-boot-starter-webmvc`, not `-web`;
  `spring-boot-starter-webmvc-test`); `TestRestTemplate` moved to
  `org.springframework.boot.resttestclient` and needs **both** the `spring-boot-resttestclient`
  dependency (the module `TestRestTemplate` itself lives in) **and** `spring-boot-restclient`
  (`TestRestTemplate` needs `RestTemplateBuilder` from it) **and**
  `@AutoConfigureTestRestTemplate` explicitly - confirmed by actually inspecting jar contents
  when the single-dependency version threw `ClassNotFoundException`, not assumed; Testcontainers
  2.x module artifacts are prefixed (`testcontainers-postgresql`, `testcontainers-junit-jupiter`),
  not the old unprefixed names.

If any of the above stops being true, don't assume it's still accurate - verify against the
actual failure before trusting this file over what's actually observed.

## Architecture (intended - update this section if implementation reveals a better shape)

**Backend**: conventional Spring layered architecture, not strict Clean Architecture - the
"domain" entities (`Cat`, `Wallet`, `Transfer`) are JPA `@Entity` classes, so the domain layer is
coupled to Hibernate/Spring. Deliberate, pragmatic choice appropriate to the project's size.

```
web/ (controllers, DTOs, error mapping)
  -> service/ (TransferService, WalletService: business rules, transaction boundaries, locking)
    -> repository/ (Spring Data JPA interfaces)
      -> domain/ (JPA entities)
```

Core correctness properties for `TransferService`:
- A transfer locks both wallets (`SELECT ... FOR UPDATE`) inside one `@Transactional` method,
  **always in a fixed order by cat ID** regardless of transfer direction, so two concurrent
  transfers between the same pair of cats can't deadlock each other.
- The DB has a `CHECK (balance_treats >= 0)` constraint independent of application code - a
  second line of defense, not the primary one.
- A concurrency test (many opposing transfers between two cats from multiple threads, asserting
  the combined balance is unchanged) is what actually proves the locking is safe - it needs to
  exist before this is considered done, not as an afterthought.

**Mobile**: stricter Clean Architecture + Cubit (BLoC), specifically to contrast with the
backend's pragmatism:

```
presentation/ (Views: dumb widgets; Cubit: orchestrates use cases, emits immutable MeowPayState)
  -> domain/ (entities, MeowPayRepository interface, use cases - ZERO Flutter/HTTP/JSON imports)
      ^
      | implements
data/ (models with JSON mapping, MeowPayRemoteDataSource, MeowPayRepositoryImpl)
```

The dependency rule that matters: **nothing in `domain/` may import `flutter/*`, `http`,
`dart:convert`, or anything from `data/`**. If a domain file ever needs one of those, the
abstraction has leaked - push the concern into `data/` or `presentation/` instead.

`MeowPayState` should be a sealed class. Adding a new state variant should be a compile error
everywhere it's not handled (an exhaustive `switch` in the View) - don't add a `default:` case to
silence that; handle the new variant.

## Testability checklist (what "good" looks like here, when extending)

- **Backend**: new business logic gets a test against real Postgres via Testcontainers
  (`@Import(TestcontainersConfig::class)`), not H2 and not a mock repository. If the logic
  touches money movement, it needs a concurrency test.
- **Mobile domain/use-cases**: plain `flutter test` against a fake repository - no widget pump
  needed. If a new use case can't be tested this way without touching Flutter, it's probably not
  actually domain logic.
- **Mobile presentation**: `bloc_test`'s `blocTest()` for the Cubit (state-emission sequences);
  `testWidgets` + `BlocProvider.value` for the View, using the same fake repository.
- Before committing: `./gradlew test` (backend), `flutter analyze && flutter test` (mobile),
  `npm run build && npx eslint .` (web). All three are meant to be clean, not just "mostly passing."

## Scalability notes (why certain things should be structured the way they are)

- Wallet balances should be stored on their own column (`wallets.balance_treats`), not derived by
  summing transfer history - O(1) balance lookup regardless of transfer-history size, at the cost
  of needing the transactional locking to keep it consistent.
- The repository-interface boundary in mobile (`domain/repositories/meowpay_repository.dart`)
  means a future local cache, offline queue, or GraphQL backend would be a new
  `MeowPayRepository` implementation, not a rewrite of `domain/` or `presentation/`.
- No auth, no idempotency key, no payment rail behind top-up - deliberate omissions for the
  stated scope, not things to add speculatively without checking whether the task at hand
  actually needs them.

## Commit style

Small, individually-buildable commits, made through the planner → coder → review → commit loop
above - verify (`analyze`/`test`/`build`) *before* committing, not after a batch of changes. This
repo's history is itself documentation of how each piece was built and verified; don't squash it.
