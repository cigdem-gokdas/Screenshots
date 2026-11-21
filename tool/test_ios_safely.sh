#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Always creates a NEW simulator. Never accepts an existing device ID, uninstalls
# an application, erases a simulator or touches the user's original iPhone 17.
test_id=$(xcrun simctl create "Screenshot Release Verification $(date +%Y%m%d-%H%M%S)" com.apple.CoreSimulator.SimDeviceType.iPhone-17 com.apple.CoreSimulator.SimRuntime.iOS-26-3)
printf '%s\n' "$test_id" > /tmp/screenshot-release-test-simulator.txt
trap 'xcrun simctl shutdown "$test_id" >/dev/null 2>&1 || true' EXIT
xcrun simctl boot "$test_id"
xcrun simctl bootstatus "$test_id" -b
umask 077
result_log=$(mktemp /private/tmp/screenshot-native-tests.XXXXXX)
"${FLUTTER_BIN:-flutter}" test integration_test --no-uninstall --dds --dds-port=0 -d "$test_id" 2>&1 | tee "$result_log"
# Flutter may exit zero after an interrupted load. Require an actual reporter
# completion marker before claiming success; the CLI exit status alone is insufficient.
if ! grep -Fq 'All tests passed!' "$result_log"; then
  printf 'Native tests did not report completion; inspect %s.\n' "$result_log" >&2
  exit 1
fi
# Restore the normal archive entry point after a successful integration run.
"${FLUTTER_BIN:-flutter}" build ios --config-only --release --no-codesign --target lib/main.dart
printf 'Native integration tests passed on dedicated simulator %s. Original simulator was untouched.\n' "$test_id"
