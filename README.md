# MeowPay (slice) — send treats

A thin, real, end-to-end slice of MeowPay: one cat sends treats to another. Kotlin/Spring Boot
backend with real Postgres persistence, a Next.js frontend, and a Flutter mobile client. The
workflow contract (`CLAUDE.md`, two agents, two skills) is the first thing committed, before a
single line of app code, so every commit that follows is made under it. See
[How I used AI](#how-i-used-ai) for how that loop actually worked, commit by commit.

**The core submission is `backend/` + `web/`** — that's the single thin slice the exercise asks
for. `mobile/` is extra, added afterward as a second client against the same backend; see
[Decisions and trade-offs](#decisions-and-trade-offs) for why it's called out separately rather
than folded into "the slice."

## What's here

- **`backend/`** — Spring Boot 4 (Kotlin) REST API. Postgres persistence via Spring Data JPA,
  schema managed with Flyway. Balances live in the database, the transfer logic runs inside a DB
  transaction with row-level locking, and constraints are enforced at the DB layer too, not just
  in application code.
- **`web/`** — Next.js 16 (App Router, TypeScript) frontend. Lists cats and their treat balances,
  a form to send treats from one cat to another, a "top up" button standing in for a human
  topping up their cat's wallet, and a transfer history feed.
- **`mobile/`** — Flutter client (Android + iOS) against the same REST API. Clean Architecture
  (domain/data/presentation) + Cubit from the very first commit — see
  [Decisions and trade-offs](#decisions-and-trade-offs) for why.
- **`.claude/`** — the workflow contract this repo was built under, checked in alongside the
  code rather than kept in a human's head: [`CLAUDE.md`](CLAUDE.md) (architecture/testability
  rules and harness quirks), [`.claude/skills/run/`](.claude/skills/run/SKILL.md) (how to launch
  each piece and confirm it's serving real traffic), [`.claude/skills/tdd/`](.claude/skills/tdd/SKILL.md)
  (the red-green-refactor workflow per stack), and two agents,
  [`tdd-planner`](.claude/agents/tdd-planner.md) and [`tdd-coder`](.claude/agents/tdd-coder.md) —
  see [How I used AI](#how-i-used-ai) for how they were actually used, commit by commit.

## Running it from a clean clone

You'll need Docker, a JDK (Gradle's toolchain auto-provisioning fetches JDK 21 itself — no local
install required), and Node (20+).

**1. Start Postgres**

```bash
docker compose up -d
```

**2. Start the backend** (from `backend/`)

```bash
cd backend
./gradlew bootRun
```

This applies the Flyway migrations (schema + three seed cats) against the Postgres container on
startup, then serves the API on `http://localhost:8080`.

**3. Start the frontend** (from `web/`, in a second terminal)

```bash
cd web
cp .env.local.example .env.local   # NEXT_PUBLIC_API_URL, defaults to http://localhost:8080
npm install
npm run dev
```

Open `http://localhost:3000`. You should see three seeded cats (Whiskers, Mochi, Biscuit) with
starting balances — send treats between them, or hit "Top up" to give a cat more treats first.

### Troubleshooting: Testcontainers / Docker on Colima

If you're running Docker via [Colima](https://github.com/abiosoft/colima) instead of Docker
Desktop, Testcontainers' cleanup sidecar ("Ryuk") can fail to start against Colima's VM
networking. If `./gradlew test` hangs or fails trying to launch containers, set:

```bash
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
export TESTCONTAINERS_RYUK_DISABLED=true
```

This isn't needed with Docker Desktop.

## Running the mobile app (Android + iOS)

Needs the [Flutter SDK](https://docs.flutter.dev/get-started/install), the backend running
(above), and either an Android emulator/device or the iOS Simulator (macOS + Xcode + CocoaPods).
Bundle/application id is `com.meowpayslice.mobile`.

```bash
cd mobile
flutter pub get
```

**iOS Simulator** — it shares the host Mac's network stack, so the default works:

```bash
flutter run -d "iPhone 17 Pro"   # or whatever simulator you have booted
```

**Android emulator** — the emulator's own network namespace means `localhost` refers to the
emulator, not your Mac, so the backend URL needs to be overridden to the emulator's
host-loopback address, `10.0.2.2`:

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Both were verified against the live backend on this machine — build, install, tap through the
actual UI (select a sender/recipient, send treats, watch balances and history update), not just
`flutter test` passing.

Run the mobile tests (55+ tests: domain/use-cases against an in-memory fake repository, the data
layer against `package:http/testing.dart`'s `MockClient`, `bloc_test` for the Cubit's state
transitions, and a widget test of the full screen — no backend or emulator needed):

```bash
flutter analyze && flutter test
```

## Running everything at once

Every piece above is an independent process against the same shared backend, so there's no need
to run them one at a time — start Postgres and the backend once, then bring up as many clients as
you want in parallel, in any order:

| Piece                    | Command (own terminal each)                                        | Serves on / reaches backend via |
|---------------------------|--------------------------------------------------------------------|----------------------------------|
| Postgres                  | `docker compose up -d`                                              | `localhost:5432`                |
| Backend                   | `cd backend && ./gradlew bootRun`                                   | `localhost:8080`                |
| Web                       | `cd web && npm run dev`                                             | `localhost:3000` → `localhost:8080` |
| Mobile (iOS Simulator)    | `cd mobile && flutter run -d "iPhone 17 Pro"`                       | → `localhost:8080` (shares host network) |
| Mobile (Android emulator) | `cd mobile && flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080` | → `10.0.2.2:8080` |

This is exactly how the mobile verification for this README was actually done: backend + web up
in the background, then both the Android emulator and iOS Simulator built, installed, and driven
through a live transfer concurrently against that one running backend — the same cats' balances
updating and showing up in every client's transfer history, since they're all hitting the same
Postgres row.

## API

| Method | Path                     | Description                                  |
|--------|--------------------------|-----------------------------------------------|
| GET    | `/api/cats`              | List cats with their current balance          |
| GET    | `/api/cats/{id}`         | Get one cat                                   |
| POST   | `/api/cats/{id}/topup`   | `{ amountTreats }` — credit a cat's wallet    |
| POST   | `/api/transfers`         | `{ fromCatId, toCatId, amountTreats }`        |
| GET    | `/api/transfers?catId=`  | Transfer history, optionally filtered by cat  |

Errors come back as `{ error, message }` with the matching status: `404` for an unknown cat,
`409` for insufficient treats, `400` for a bad request (self-transfer, non-positive amount,
missing field).

## Running the tests

```bash
cd backend
./gradlew test
```

All backend tests run against a real Postgres via Testcontainers (not H2, not mocks) — repository
tests exercising the DB `CHECK` constraints directly, an end-to-end test going through the actual
HTTP layer (`TestRestTemplate`), and a concurrency test that fires many opposing transfers between
the same two cats from multiple threads at once and asserts the combined balance is unchanged, to
exercise the row-locking. That locking strategy was validated empirically, not just by reading the
code: it was deliberately broken (role-based instead of fixed-order locking) to confirm the
concurrency test actually catches real Postgres deadlocks, then reverted.

## Decisions and trade-offs

- **Real persistence, real locking.** Balances are stored on a `wallets` table (not derived by
  summing transfer history), and a transfer locks both wallets with `SELECT ... FOR UPDATE`
  inside a single transaction, always in a fixed order (by cat id) regardless of transfer
  direction — so two concurrent transfers between the same pair of cats can't deadlock each
  other. A DB-level `CHECK (balance_treats >= 0)` constraint is a second line of defense against
  ever going negative, independent of the application code.
- **Treats are whole numbers.** No fractional treats, no currency/decimal precision concerns —
  keeps the money-movement logic simple (`Long` counts, no floating point) while still
  exercising the real shape of the problem (debit one account, credit another, atomically).
- **Seeded cats, no auth, no human-facing identity on `Cat`.** Three cats are seeded by a Flyway
  migration and the UI lets you act as any of them; `Cat` carries no email or owner field at all.
  A real product needs authentication and authorization (a cat's human should only be able to
  spend that cat's treats) — scoped out to keep the slice thin and focused on transfer mechanics.
- **No idempotency key on `POST /transfers`.** A real payments API needs one so a client retry
  (flaky network, double-tap) can't double-send. Skipped here for time — noting it explicitly
  rather than silently shipping a double-spend risk.
- **Top-up is a stand-in, not a real payment.** `POST /cats/{id}/topup` just credits the ledger
  directly — there's no external payment rail behind it. It exists so the demo has treats to send
  without building a payment integration for a slice that's about the *transfer*, not the top-up.
- **CORS is locked to the frontend's dev origin** rather than wide open, since this is meant to
  model a real backend, not a toy.
- **Why Postgres over H2:** the brief calls out "a running service with real persistence and
  logic, not a UI over mocked data" — a real Postgres instance, with the same row-locking
  behavior a production deployment would have, is what actually backs the concurrency test.
- **The Flutter app is intentionally scoped outside "the slice."** A third client on two more
  platforms doesn't make the transfer logic any more correct — it's added surface area, kept
  separate from `backend/`/`web/` decisions on purpose (see `CLAUDE.md`).
- **Cubit (BLoC) for the mobile presentation layer, from the first commit.** `MeowPayState` is a
  sealed class from the start — adding a new state variant is a compile error everywhere it isn't
  handled, since `HomeScreen`'s `switch` is exhaustive. `MeowPayLoaded.copyWith` was designed with
  mutually exclusive `formError`/`formSuccess` fields (with an `assert` invariant), so an error and
  a success message can never render at the same time.
- **The mobile data layer has its own testability rule, added before it was built.** JSON mapping
  and HTTP error-to-failure mapping are the kind of logic that can regress silently as "the UI
  shows the wrong error copy" rather than as a crash, so `CLAUDE.md` carries an explicit checklist
  entry for this layer (commit `fc0601c`) written *before* `data/` was implemented. The actual
  implementation has a test per `MeowPayRemoteDataSource` operation against `MockClient`, plus a
  test per distinct failure-mapping branch asserting the resulting `MeowPayFailure` subtype.

## How I used AI

The workflow contract — `CLAUDE.md`, two agents, two skills — was committed first, before a
single line of app code, in this sequence from a fresh `git init`:

```
459fdc2  chore: init repo
97d914d  docs: add tdd-planner and tdd-coder agents
90793eb  docs: add run/tdd skills
4969bcc  docs: add CLAUDE.md - the workflow contract, written before any app code
...      (all subsequent app-code commits)
```

**Two agents, not one, with a hard split between planning and implementing:**

- **[`.claude/agents/tdd-planner.md`](.claude/agents/tdd-planner.md)** — read-only
  (`Read`/`Grep`/`Glob`/`Bash`, no `Edit`/`Write`). Reads `CLAUDE.md`'s architecture/testability
  rules, the skills below, and whatever code already exists near the change, then hands back a
  concrete test-first plan: which layers change, the first failing test in concrete terms, what
  "green" looks like, what's deliberately not covered, and named regression risk. It cannot write
  code — the point is that a plan gets checked against the architecture before anyone commits to
  an approach.
- **[`.claude/agents/tdd-coder.md`](.claude/agents/tdd-coder.md)** — has `Write`/`Edit`/`Bash`.
  Takes a `tdd-planner` plan and actually executes red-green-refactor: writes the failing test,
  confirms it fails for the right reason, writes the minimal code to pass it, runs the **full**
  existing suite for that stack to check for regressions, and reports back what changed and the
  verification result. It never runs `git commit` itself and never touches an existing test's
  assertions without flagging it for explicit sign-off first.

Every non-trivial piece of this repo's application code — the backend's domain model, locking
service, and API; the web UI; all three mobile layers — went through
`tdd-planner` → `tdd-coder` → my own independent re-verification (re-running `flutter
analyze`/`flutter test`, `./gradlew test`, or the live browser/device check, never just trusting
the agent's self-report) → commit. Small, individually-buildable commits throughout, every one of
them made under a workflow that existed before the code did.

**Concrete things this loop caught, not just process for its own sake:**

- `tdd-planner` flagged that `test/widget_test.dart`'s counter-app template would need its
  assertions replaced (not just added to) to become a real `HomeScreen` test — per `CLAUDE.md`'s
  "no regression without sign-off" rule, that needed explicit approval before `tdd-coder` touched
  it, since it's the one sanctioned case of touching an existing test's assertions in this repo
  (pure scaffold noise, zero product behavior).
- `tdd-coder` found the backend had no CORS configuration at all while verifying the web UI live
  against the real backend — every browser fetch would have failed regardless of origin. Fixed
  and committed separately (`45b92d1`) from the UI commit itself, since it's a distinct concern.
- The locking strategy and the `copyWith` invariant were both validated empirically, not just by
  reading the code: role-based (instead of fixed-order) wallet locking was tried deliberately,
  producing 17 real Postgres deadlocks in ~25s, before being reverted to fixed-order locking
  (~0.8s, zero deadlocks); and a naive, non-mutually-exclusive `MeowPayLoaded.copyWith` was tried
  and confirmed to fail an assertion (`formError` should be `null` after a success, wasn't) before
  being reverted to the correct version.
- `CLAUDE.md` itself was corrected mid-build, not just written once and left alone: the
  `TestRestTemplate` dependency note was wrong (needed **both**
  `spring-boot-resttestclient` and `spring-boot-restclient`, not one), caught by an actual
  `ClassNotFoundException` and fixed in a dedicated docs commit (`7f2e99b`) rather than papered
  over inline.

Mobile was verified live on both platforms before this README was written — a real Android
emulator and the iOS Simulator, both built and installed from scratch, both driven through an
actual transfer end-to-end (select sender/recipient, enter an amount, tap Send, watch the balance
and history update against the shared live backend) and a top-up, not just a build succeeding or
`flutter test` passing.
