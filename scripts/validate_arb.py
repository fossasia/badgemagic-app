#!/usr/bin/env python3
"""Validate translated ARB files against the English source of truth.

For every lib/l10n/app_*.arb (other than app_en.arb) this reports:
  * missing keys      - present in app_en.arb, absent from the target
  * extra keys        - present in the target, absent from app_en.arb
  * placeholder diffs - the set of {placeholder} names differs from English

Keys starting with '@' (ARB metadata) are compared for presence but are not
checked for placeholders.

Exit status is 1 if any file has errors, 0 otherwise.

Usage:
    python3 scripts/validate_arb.py
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = REPO_ROOT / "lib" / "l10n"
SOURCE_FILE = L10N_DIR / "app_en.arb"

# Matches simple placeholders ({name}) and the argument name of ICU
# plural/select expressions ({count, plural, ...}).
PLACEHOLDER_RE = re.compile(r"\{\s*([A-Za-z_]\w*)\s*(?=[,}])")


def load_arb(path):
    """Return the parsed ARB as a dict, or raise ValueError with a reason."""
    try:
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        raise ValueError(f"invalid JSON: {e}") from e
    except OSError as e:
        raise ValueError(f"cannot read file: {e}") from e
    if not isinstance(data, dict):
        raise ValueError("top-level JSON value is not an object")
    return data


def extract_placeholders(value):
    if not isinstance(value, str):
        return set()
    return set(PLACEHOLDER_RE.findall(value))


def validate(source, target):
    """Compare target against source; return (missing, extra, mismatches)."""
    source_keys = set(source)
    target_keys = set(target)

    missing = sorted(source_keys - target_keys)
    extra = sorted(target_keys - source_keys)

    mismatches = []
    for key in sorted(source_keys & target_keys):
        if key.startswith("@"):
            continue
        expected = extract_placeholders(source[key])
        actual = extract_placeholders(target[key])
        if expected != actual:
            mismatches.append((key, expected, actual))

    return missing, extra, mismatches


def fmt_set(items):
    return "{" + ", ".join(sorted(items)) + "}" if items else "{}"


def print_summary(rows):
    headers = ("File", "Missing", "Extra", "Placeholder", "Status")
    table = [headers] + [
        (
            name,
            str(missing),
            str(extra),
            str(placeholder),
            status,
        )
        for name, missing, extra, placeholder, status in rows
    ]
    widths = [max(len(row[i]) for row in table) for i in range(len(headers))]

    def line(row):
        return "  ".join(
            cell.ljust(w) if i == 0 or i == len(row) - 1 else cell.rjust(w)
            for i, (cell, w) in enumerate(zip(row, widths))
        )

    print()
    print("Summary")
    print(line(headers))
    print("  ".join("-" * w for w in widths))
    for row in table[1:]:
        print(line(row))


def main():
    if not SOURCE_FILE.is_file():
        print(f"error: source file not found: {SOURCE_FILE}", file=sys.stderr)
        return 1

    try:
        source = load_arb(SOURCE_FILE)
    except ValueError as e:
        print(f"error: {SOURCE_FILE.name}: {e}", file=sys.stderr)
        return 1

    targets = sorted(p for p in L10N_DIR.glob("app_*.arb") if p != SOURCE_FILE)
    if not targets:
        print(f"No target ARB files found in {L10N_DIR}")
        return 0

    rows = []
    has_errors = False

    for path in targets:
        try:
            target = load_arb(path)
        except ValueError as e:
            print(f"\n[{path.name}] ERROR: {e}")
            rows.append((path.name, "-", "-", "-", "INVALID"))
            has_errors = True
            continue

        missing, extra, mismatches = validate(source, target)
        failed = bool(missing or extra or mismatches)
        has_errors = has_errors or failed

        if failed:
            print(f"\n[{path.name}]")
            for key in missing:
                print(f"  missing key: {key}")
            for key in extra:
                print(f"  extra key:   {key}")
            for key, expected, actual in mismatches:
                print(
                    f"  placeholder mismatch: {key} "
                    f"(en: {fmt_set(expected)}, {path.stem[4:]}: {fmt_set(actual)})"
                )

        rows.append(
            (
                path.name,
                len(missing),
                len(extra),
                len(mismatches),
                "FAIL" if failed else "OK",
            )
        )

    print_summary([tuple(str(c) for c in row) for row in rows])

    failed_count = sum(1 for row in rows if row[4] != "OK")
    print(f"\n{len(rows)} file(s) checked, {failed_count} with errors.")
    return 1 if has_errors else 0


if __name__ == "__main__":
    sys.exit(main())
