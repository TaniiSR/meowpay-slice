---
name: run
description: Launch MeowPay (backend + web by default; mobile on request) and verify it's actually serving traffic, not just started. Use whenever asked to run, start, preview, or verify MeowPay works.
---

# Running MeowPay

Three independent pieces. Unless told otherwise, start **backend + web** (the actual
submission) - don't launch `mobile/` unless it's specifically requested, since it's out-of-scope
extra surface (see root `CLAUDE.md`).

## 1. Postgres

```bash
cd <repo root>
docker-compose up -d
```

If Docker isn't reachable at all (not just slow - actually failing), check whether Docker
Desktop or an alternative (Colima) is running before assuming something else is broken.

## 2. Backend

```bash
cd backend
./gradlew bootRun
```

Run this **in the background** (it's a long-lived server, not a one-shot command) and poll for
readiness rather than assuming a fixed startup time:

```bash
for i in $(seq 1 30); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/cats 2>/dev/null)
  [ "$code" = "200" ] && echo "backend up" && break
  sleep 2
done
```

A cold start (first run, or after `flutter clean`-style cache wipes) can take much longer than a
warm one - don't conclude something's hung after 10-15s if it's the very first run this session.

## 3. Web

```bash
cd web
cp -n .env.local.example .env.local   # only if .env.local doesn't already exist
npm install                            # only if node_modules is missing/stale
npm run dev
```

Also background; poll `http://localhost:3000` for a 200 the same way. Open it in the Browser
pane once it's up, don't just assume the terminal log line means it's actually serving.

## 4. Mobile (only if explicitly asked)

Ask (or infer from context) which platform - don't build both unless told to. Bundle/application
id is `com.meowpayslice.mobile` - deliberately different from the sibling `meowpay` repo's
`com.meowpay.mobile` so both can be installed on the same simulator/emulator at once without
clobbering each other.

**iOS Simulator:**
```bash
xcrun simctl boot "iPhone 17 Pro"   # or whatever's available; skip if one's already booted
cd mobile
flutter build ios --debug --simulator
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.meowpayslice.mobile
```
Default `API_BASE_URL` (`http://localhost:8080`) works as-is - the Simulator shares the host's
network stack.

**Android emulator:**
```bash
flutter emulators --launch Pixel_9_Pro   # or another id from `flutter emulators`
# wait for `adb shell getprop sys.boot_completed` to return 1
cd mobile
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.meowpayslice.mobile/.MainActivity
```
`localhost` does **not** work here - the emulator's own network namespace makes that resolve to
itself, not the host Mac. This is the single most common "why is mobile showing a network error"
cause; check the `--dart-define` before debugging anything else.

## Verifying it's real, not just "started"

Don't stop at "the command didn't error." For each piece actually running, confirm it's serving
real data from the real (shared) backend:

```bash
curl -s http://localhost:8080/api/cats   # should list Whiskers/Mochi/Biscuit with real balances
```

For mobile, a screenshot showing live balances (not the Flutter splash logo, not a loading
spinner stuck for more than a few seconds) is the bar - see `CLAUDE.md`'s harness section for
what a normal vs. hung cold start looks like on each platform.
