#!/usr/bin/env python3
"""Validate translated ARB files against the English source of truth.

For every lib/l10n/app_*.arb (other than app_en.arb) this reports:
  * missing keys       - present in app_en.arb, absent from the target
  * extra keys         - present in the target, absent from app_en.arb
  * placeholder diffs  - the set of {placeholder} names differs from English
  * type errors        - value is not a string
  * artifact errors    - literal placeholder markers (e.g. __PH_) found

Keys starting with '@' (ARB metadata) are compared for presence but are not
checked for placeholders.

Usage:
    python3 scripts/validate_arb.py                     # Validate all ARB files
    python3 scripts/validate_arb.py --target app_hi.arb # Validate specific locale
    python3 scripts/validate_arb.py --report            # Summary report only
"""

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = REPO_ROOT / "lib" / "l10n"
SOURCE_FILE = L10N_DIR / "app_en.arb"

PLACEHOLDER_RE = re.compile(r"\{\s*([A-Za-z_]\w*)\s*(?=[,}])")
ARTIFACT_RE = re.compile(r"__\s*PH_[A-Za-z0-9_]*\s*__", re.IGNORECASE)


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
    """Compare target against source; return (missing, extra, mismatches, type_errors, artifacts)."""
    source_keys = set(source)
    target_keys = set(target)

    missing = sorted(source_keys - target_keys)
    extra = sorted(target_keys - source_keys)

    mismatches = []
    type_errors = []
    artifacts = []

    for key in sorted(source_keys & target_keys):
        if key.startswith("@"):
            continue
        val = target[key]
        if not isinstance(val, str):
            type_errors.append((key, type(val).__name__))
            continue

        if ARTIFACT_RE.search(val) or "__PH_" in val:
            artifacts.append(key)

        expected = extract_placeholders(source[key])
        actual = extract_placeholders(val)
        if expected != actual:
            mismatches.append((key, expected, actual))

    return missing, extra, mismatches, type_errors, artifacts


def fmt_set(items):
    return "{" + ", ".join(sorted(items)) + "}" if items else "{}"


def print_summary(rows):
    headers = ("File", "Missing", "Extra", "Placeholders", "Errors", "Status")
    table = [headers] + [
        (
            name,
            str(missing),
            str(extra),
            str(placeholder),
            str(errors),
            status,
        )
        for name, missing, extra, placeholder, errors, status in rows
    ]
    widths = [max(len(row[i]) for row in table) for i in range(len(headers))]

    def line(row):
        return "  ".join(
            cell.ljust(w) if i == 0 or i == len(row) - 1 else cell.rjust(w)
            for i, (cell, w) in enumerate(zip(row, widths))
        )

    print("\nSummary")
    print(line(headers))
    print("  ".join("-" * w for w in widths))
    for row in table[1:]:
        print(line(row))


def main():
    parser = argparse.ArgumentParser(description="Validate ARB localization files.")
    parser.add_argument(
        "--target",
        type=str,
        default=None,
        help="Specific ARB filename or path to validate (e.g. app_hi.arb)",
    )
    parser.add_argument(
        "--report",
        action="store_true",
        help="Print summary report without failing on un-migrated empty locales",
    )
    args = parser.parse_args()

    if not SOURCE_FILE.is_file():
        print(f"error: source file not found: {SOURCE_FILE}", file=sys.stderr)
        return 1

    try:
        source = load_arb(SOURCE_FILE)
    except ValueError as e:
        print(f"error: {SOURCE_FILE.name}: {e}", file=sys.stderr)
        return 1

    if args.target:
        target_path = Path(args.target)
        if not target_path.is_file():
            target_path = L10N_DIR / args.target
        if not target_path.is_file():
            print(f"error: target file not found: {args.target}", file=sys.stderr)
            return 1
        targets = [target_path]
    else:
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
            rows.append((path.name, "-", "-", "-", "-", "INVALID"))
            has_errors = True
            continue

        missing, extra, mismatches, type_errors, artifacts = validate(source, target)
        error_count = len(type_errors) + len(artifacts)
        failed = bool(missing or extra or mismatches or error_count)
        if not args.report:
            has_errors = has_errors or failed

        if failed and (args.target or len(missing) < 50):
            print(f"\n[{path.name}]")
            for key in missing:
                print(f"  missing key: {key}")
            for key in extra:
                print(f"  extra key:   {key}")
            for key, tname in type_errors:
                print(f"  type error:  {key} (expected str, got {tname})")
            for key in artifacts:
                print(f"  artifact:    {key} (contains unparsed placeholder token)")
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
                error_count,
                "FAIL" if failed else "OK",
            )
        )

    print_summary([tuple(str(c) for c in row) for row in rows])

    failed_count = sum(1 for row in rows if row[5] != "OK")
    print(f"\n{len(rows)} file(s) checked, {failed_count} with errors.")
    return 1 if has_errors else 0


if __name__ == "__main__":
    sys.exit(main())
