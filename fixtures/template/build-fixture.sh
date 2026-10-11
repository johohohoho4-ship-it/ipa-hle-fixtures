#!/usr/bin/env bash
set -euo pipefail

FIXTURE="${1:-}"
if [[ ! "$FIXTURE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Fixture must be a lowercase slug such as uikit-form; got: $FIXTURE" >&2
  exit 2
fi

WORKSPACE="${GITHUB_WORKSPACE:?This script runs in GitHub Actions}"
RUNNER_TEMP="${RUNNER_TEMP:?This script runs in GitHub Actions}"
FIXTURE_DIR="$WORKSPACE/fixtures/$FIXTURE"
CONFIG_PATH="$FIXTURE_DIR/ipa-hle-fixture.json"
OUT="$RUNNER_TEMP/ipa-hle-fixture-artifacts/$FIXTURE"

mkdir -p "$OUT"
echo "fixture=$FIXTURE" >> "$GITHUB_OUTPUT"

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "Missing fixture configuration: $CONFIG_PATH" >&2
  exit 2
fi

CONFIG_VALUES="$(python3 - "$CONFIG_PATH" "$FIXTURE_DIR" <<'PY'
import json
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1]).resolve(strict=True)
fixture_dir = Path(sys.argv[2]).resolve(strict=True)
config = json.loads(config_path.read_text(encoding="utf-8"))

def value(name):
    result = config.get(name)
    if not isinstance(result, str) or not result or any(char in result for char in "\r\n\t"):
        raise SystemExit(f"{name} must be a non-empty single-line string")
    return result

project_rel = Path(value("project"))
if project_rel.is_absolute() or ".." in project_rel.parts:
    raise SystemExit("project must stay inside the fixture directory")
project_path = (fixture_dir / project_rel).resolve(strict=True)
try:
    project_path.relative_to(fixture_dir)
except ValueError:
    raise SystemExit("project resolves outside the fixture directory")
if project_path.suffix not in {".xcodeproj", ".xcworkspace"}:
    raise SystemExit("project must name an .xcodeproj or .xcworkspace")
kind = "-workspace" if project_path.suffix == ".xcworkspace" else "-project"

scheme = value("scheme")
app_name = value("app_name")
bundle_id = value("bundle_id")
minimum_ios = value("minimum_ios")
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 ._-]{0,63}", scheme):
    raise SystemExit("scheme contains unsupported characters")
if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,63}", app_name):
    raise SystemExit("app_name contains unsupported characters")
if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle_id):
    raise SystemExit("bundle_id is not a reverse-DNS identifier")
if not re.fullmatch(r"\d+\.\d+(?:\.\d+)?", minimum_ios):
    raise SystemExit("minimum_ios must look like 15.0 or 15.0.1")

print("\t".join((kind, str(project_path), scheme, app_name, bundle_id, minimum_ios)))
PY
)"
IFS=$'\t' read -r PROJECT_FLAG PROJECT_PATH SCHEME APP_NAME BUNDLE_ID MINIMUM_IOS <<< "$CONFIG_VALUES"

XCODE_DEVELOPER="${XCODE_DEVELOPER:-/Applications/Xcode_16.4.app/Contents/Developer}"
EXPECTED_XCODE="16.4"
EXPECTED_SDK="18.5"
if [[ ! -d "$XCODE_DEVELOPER" ]]; then
  echo "Pinned Xcode is missing: $XCODE_DEVELOPER" >&2
  exit 1
fi
sudo xcode-select --switch "$XCODE_DEVELOPER"

XCODE_VERSION="$(xcodebuild -version | awk '/^Xcode / { print $2 }')"
XCODE_BUILD="$(xcodebuild -version | awk '/^Build version / { print $3 }')"
DEVICE_SDK="$(xcrun --sdk iphoneos --show-sdk-version)"
SIMULATOR_SDK="$(xcrun --sdk iphonesimulator --show-sdk-version)"
if [[ "$XCODE_VERSION" != "$EXPECTED_XCODE" ]]; then
  echo "Expected Xcode $EXPECTED_XCODE, found $XCODE_VERSION" >&2
  exit 1
fi
if [[ "$DEVICE_SDK" != "$EXPECTED_SDK" || "$SIMULATOR_SDK" != "$EXPECTED_SDK" ]]; then
  echo "Expected iOS device and Simulator SDK $EXPECTED_SDK; found $DEVICE_SDK and $SIMULATOR_SDK" >&2
  exit 1
fi

cat > "$OUT/toolchain.txt" <<EOF
Runner: ${RUNNER_OS:-macOS} / $(uname -m)
Xcode: $XCODE_VERSION ($XCODE_BUILD)
iPhoneOS SDK: $DEVICE_SDK
iPhoneSimulator SDK: $SIMULATOR_SDK
Simulator runtime: iOS 18.5
Simulator device: iPhone 16
EOF
xcodebuild -showsdks >> "$OUT/toolchain.txt"

DEVICE_DERIVED="$RUNNER_TEMP/$FIXTURE-device-derived"
DEVICE_PRODUCTS="$DEVICE_DERIVED/Build/Products/Release-iphoneos"
xcodebuild "$PROJECT_FLAG" "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DEVICE_DERIVED" \
  ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO \
  STRIP_INSTALLED_PRODUCT=NO \
  COPY_PHASE_STRIP=NO \
  DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
  build | tee "$OUT/iphoneos-build.log"

APP_PATH="$DEVICE_PRODUCTS/$APP_NAME.app"
EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Info.plist")"
FOUND_BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")"
FOUND_MINIMUM_IOS="$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$APP_PATH/Info.plist")"
if [[ "$FOUND_BUNDLE_ID" != "$BUNDLE_ID" || "$FOUND_MINIMUM_IOS" != "$MINIMUM_IOS" ]]; then
  echo "Built app metadata does not match ipa-hle-fixture.json" >&2
  exit 1
fi
test -f "$APP_PATH/$EXECUTABLE"
ARCHITECTURES="$(lipo -archs "$APP_PATH/$EXECUTABLE")"
if [[ " $ARCHITECTURES " != *" arm64 "* ]]; then
  echo "Expected an arm64 executable, found: $ARCHITECTURES" >&2
  exit 1
fi
CRYPTID="$(otool -l "$APP_PATH/$EXECUTABLE" | awk '
  $1 == "cmd" && $2 == "LC_ENCRYPTION_INFO_64" { in_encryption = 1; next }
  in_encryption && $1 == "cryptid" { print $2; found = 1; exit }
  END { if (!found) exit 1 }
')"
if [[ "$CRYPTID" != "0" ]]; then
  echo "Expected cryptid=0, found: $CRYPTID" >&2
  exit 1
fi

DSYM_PATH="$DEVICE_PRODUCTS/$APP_NAME.app.dSYM"
if [[ ! -d "$DSYM_PATH" ]]; then
  echo "Xcode did not produce the expected dSYM: $DSYM_PATH" >&2
  exit 1
fi
nm -a "$APP_PATH/$EXECUTABLE" > "$OUT/$APP_NAME-symbol-table.txt"
test -s "$OUT/$APP_NAME-symbol-table.txt"
dwarfdump --uuid "$DSYM_PATH" > "$OUT/$APP_NAME-dsym-uuids.txt"
ditto -c -k --sequesterRsrc --keepParent "$DSYM_PATH" "$OUT/$APP_NAME.app.dSYM.zip"

IPA_STAGING="$RUNNER_TEMP/$FIXTURE-ipa/Payload"
mkdir -p "$IPA_STAGING"
cp -R "$APP_PATH" "$IPA_STAGING/$APP_NAME.app"
ditto -c -k --sequesterRsrc --keepParent "$RUNNER_TEMP/$FIXTURE-ipa/Payload" "$OUT/$APP_NAME-unsigned.ipa"

SIM_DERIVED="$RUNNER_TEMP/$FIXTURE-simulator-derived"
SIM_PRODUCTS="$SIM_DERIVED/Build/Products/Release-iphonesimulator"
xcodebuild "$PROJECT_FLAG" "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$SIM_DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  build | tee "$OUT/iphonesimulator-build.log"

RUNTIME_ID="com.apple.CoreSimulator.SimRuntime.iOS-18-5"
DEVICE_TYPE_ID="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
xcrun simctl list -j > "$RUNNER_TEMP/simctl-list.json"
python3 - "$RUNNER_TEMP/simctl-list.json" "$RUNTIME_ID" "$DEVICE_TYPE_ID" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
runtime_id, device_type_id = sys.argv[2:]
runtime = next((item for item in data.get("runtimes", []) if item.get("identifier") == runtime_id and item.get("isAvailable", True)), None)
device = next((item for item in data.get("devicetypes", []) if item.get("identifier") == device_type_id), None)
if runtime is None:
    raise SystemExit(f"Pinned Simulator runtime is unavailable: {runtime_id}")
if device is None:
    raise SystemExit(f"Pinned Simulator device is unavailable: {device_type_id}")
print(f"Using {runtime['name']} ({runtime_id}) and {device['name']} ({device_type_id})")
PY

SIMULATOR_UDID="$(xcrun simctl create "$FIXTURE-reference-iPhone-16" "$DEVICE_TYPE_ID" "$RUNTIME_ID")"
xcrun simctl boot "$SIMULATOR_UDID"
xcrun simctl bootstatus "$SIMULATOR_UDID" -b
xcrun simctl ui "$SIMULATOR_UDID" appearance light
xcrun simctl ui "$SIMULATOR_UDID" content_size standard
xcrun simctl status_bar "$SIMULATOR_UDID" override \
  --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl install "$SIMULATOR_UDID" "$SIM_PRODUCTS/$APP_NAME.app"
xcrun simctl launch "$SIMULATOR_UDID" "$BUNDLE_ID"
sleep 3
xcrun simctl io "$SIMULATOR_UDID" screenshot "$OUT/$APP_NAME-simulator-cold-start.png"
xcrun simctl terminate "$SIMULATOR_UDID" "$BUNDLE_ID"

RESULT_BUNDLE="$RUNNER_TEMP/$FIXTURE.xcresult"
TEST_EXIT=0
if xcodebuild test "$PROJECT_FLAG" "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
  -derivedDataPath "$SIM_DERIVED" \
  -resultBundlePath "$RESULT_BUNDLE" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  | tee "$OUT/xcodebuild-test.log"; then
  TEST_EXIT=0
else
  TEST_EXIT=$?
fi
if ! xcrun xcresulttool get test-results summary --path "$RESULT_BUNDLE" --format json > "$OUT/xcuitest-summary.json"; then
  echo "Could not export the XCUITest summary; inspect the retained xcresult and xcodebuild-test.log" >&2
fi
# Export the test runner's console when Xcode retained one. App stdout belongs
# to a separate process; instrumented fixtures can also retain it in their tmp.
if ! xcrun xcresulttool get log --path "$RESULT_BUNDLE" --type console > "$OUT/console-log.json" 2> "$OUT/console-log-export.stderr"; then
  echo "Console log export unavailable; inspect the retained xcresult and console-log-export.stderr" >&2
fi
if SIM_DATA="$(xcrun simctl get_app_container "$SIMULATOR_UDID" "$BUNDLE_ID" data 2>/dev/null)"; then
  if [[ -f "$SIM_DATA/tmp/ipa-hle-console.log" ]]; then
    cp "$SIM_DATA/tmp/ipa-hle-console.log" "$OUT/app-console.log"
  fi
fi
if ! xcrun xcresulttool export attachments --path "$RESULT_BUNDLE" --output-path "$OUT/test-attachments"; then
  echo "Could not export XCUITest attachments; inspect the retained xcresult" >&2
fi
if [[ -d "$RESULT_BUNDLE" ]]; then
  ditto -c -k --sequesterRsrc --keepParent "$RESULT_BUNDLE" "$OUT/$APP_NAME-xcuitest.xcresult.zip" || \
    echo "Could not archive the XCUITest result bundle" >&2
fi

python3 - "$OUT" "$FIXTURE" "$PROJECT_PATH" "$SCHEME" "$APP_NAME" "$BUNDLE_ID" "$MINIMUM_IOS" "$XCODE_VERSION" "$XCODE_BUILD" "$DEVICE_SDK" "$SIMULATOR_SDK" "$CRYPTID" "$ARCHITECTURES" "$SIMULATOR_UDID" <<'PY'
import hashlib
import json
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
(out / "build-manifest.json").write_text(json.dumps({
    "fixture": sys.argv[2],
    "project": sys.argv[3],
    "scheme": sys.argv[4],
    "app_name": sys.argv[5],
    "bundle_id": sys.argv[6],
    "minimum_ios": sys.argv[7],
    "xcode": {"version": sys.argv[8], "build": sys.argv[9]},
    "sdks": {"iphoneos": sys.argv[10], "iphonesimulator": sys.argv[11]},
    "device": {"architectures": sys.argv[13].split(), "cryptid": int(sys.argv[12])},
    "simulator": {"runtime": "iOS 18.5", "device": "iPhone 16", "udid": sys.argv[14]},
    "symbols": {"strip_installed_product": False, "dSYM": f"{sys.argv[5]}.app.dSYM.zip"},
    "tests": {"framework": "XCUITest", "summary": "xcuitest-summary.json"},
}, indent=2) + "\n", encoding="utf-8")

def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()

lines = [f"{sha256(path)}  {path.name}" for path in sorted(out.iterdir()) if path.is_file() and path.name != "SHA256SUMS.txt"]
(out / "SHA256SUMS.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

if [[ "$TEST_EXIT" -ne 0 ]]; then
  echo "xcodebuild test failed with exit code $TEST_EXIT; diagnostics were exported above" >&2
  exit "$TEST_EXIT"
fi
python3 - "$OUT/xcuitest-summary.json" <<'PY'
import json
import sys

summary = json.load(open(sys.argv[1], encoding="utf-8"))
if summary.get("result") != "Passed" or summary.get("passedTests", 0) < 1:
    raise SystemExit(f"Expected at least one passing XCUITest: {summary.get('result')}")
print(f"XCUITest passed: {summary['passedTests']} test(s)")
PY
