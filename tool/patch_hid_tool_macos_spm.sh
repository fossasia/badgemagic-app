#!/usr/bin/env bash
# Rewrites hid_tool's SwiftPM hidapi path to an absolute path.
#
# Flutter symlinks plugins under macos/Flutter/ephemeral/Packages/, so the
# relative path in hid_tool's Package.swift (`../../third_party/hidapi`)
# resolves to a missing Packages/third_party/hidapi location. Pointing at the
# real vendored package in the pub cache fixes macOS builds (see #1994).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_CONFIG="${ROOT}/.dart_tool/package_config.json"

if [[ ! -f "${PACKAGE_CONFIG}" ]]; then
  echo "error: ${PACKAGE_CONFIG} not found; run 'flutter pub get' first" >&2
  exit 1
fi

python3 - "${PACKAGE_CONFIG}" <<'PY'
import pathlib
import re
import sys
import urllib.parse
import urllib.request

package_config = pathlib.Path(sys.argv[1])
data = package_config.read_text(encoding="utf-8")

# Prefer the stdlib json module when available.
import json

packages = json.loads(data)["packages"]
hid = next((p for p in packages if p["name"] == "hid_tool"), None)
if hid is None:
    print("hid_tool is not in package_config.json; nothing to patch")
    sys.exit(0)

root_uri = hid["rootUri"]
if root_uri.startswith("file:"):
    hid_root = pathlib.Path(urllib.request.url2pathname(urllib.parse.urlparse(root_uri).path))
else:
    hid_root = (package_config.parent / root_uri).resolve()

manifest = hid_root / "macos" / "hid_tool" / "Package.swift"
hidapi = (hid_root / "third_party" / "hidapi").resolve()

if not manifest.is_file():
    print(f"error: Package.swift not found at {manifest}", file=sys.stderr)
    sys.exit(1)
if not (hidapi / "Package.swift").is_file():
    print(f"error: hidapi package not found at {hidapi}", file=sys.stderr)
    sys.exit(1)

text = manifest.read_text(encoding="utf-8")
pattern = re.compile(
    r'\.package\(\s*name:\s*"hidapi"\s*,\s*path:\s*"[^"]+"\s*\)',
    re.MULTILINE,
)
replacement = f'.package(name: "hidapi", path: "{hidapi.as_posix()}")'
new_text, count = pattern.subn(replacement, text, count=1)
if count != 1:
    print(f"error: could not find hidapi path dependency in {manifest}", file=sys.stderr)
    sys.exit(1)

if new_text == text:
    print(f"hid_tool SPM hidapi path already patched -> {hidapi}")
    sys.exit(0)

manifest.write_text(new_text, encoding="utf-8")
print(f"Patched {manifest}")
print(f"  hidapi -> {hidapi}")
PY
