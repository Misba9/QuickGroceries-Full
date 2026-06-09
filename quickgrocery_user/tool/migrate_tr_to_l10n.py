#!/usr/bin/env python3
"""Migrate easy_localization .tr() calls to context.l10n (gen_l10n)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

KEY_RENAMES = {"continue": "continueAction"}

IMPORT_OLD = "import 'package:easy_localization/easy_localization.dart';"
IMPORT_L10N = "import 'package:quickgrocery/core/localization/l10n_extension.dart';"

# Files that use .tr() outside widget build (no context) — skip auto context.l10n.
SKIP_FILES: set[str] = set()


def migrate_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if ".tr(" not in text and ".tr()" not in text and IMPORT_OLD not in text:
        return False

    original = text

    if IMPORT_OLD in text:
        text = text.replace(IMPORT_OLD + "\n", "")
        if IMPORT_L10N not in text:
            # Insert after first import block.
            lines = text.splitlines(keepends=True)
            insert_at = 0
            for i, line in enumerate(lines):
                if line.startswith("import "):
                    insert_at = i + 1
            lines.insert(insert_at, IMPORT_L10N + "\n")
            text = "".join(lines)

    # namedArgs: resend_otp_in, items_in_category, coupons_available, coupon_*, etc.
    def named_repl(match: re.Match[str]) -> str:
        key = match.group("key")
        args_blob = match.group("args")
        key = KEY_RENAMES.get(key, key)
        # seconds
        m = re.search(r"'seconds'\s*:\s*'?\$?(\w+)'?", args_blob)
        if m:
            return f"context.l10n.{key}({m.group(1)})"
        m = re.search(r"'count'\s*:\s*'?\$?(\w+)'?", args_blob)
        if m:
            return f"context.l10n.{key}({m.group(1)})"
        m = re.search(r"'code'\s*:\s*(\w+)", args_blob)
        if m:
            return f"context.l10n.{key}({m.group(1)})"
        m = re.search(r"'amount'\s*:\s*(\w+)", args_blob)
        if m:
            return f"context.l10n.{key}({m.group(1)})"
        m = re.search(r"'number'\s*:\s*(\w+)", args_blob)
        if m:
            return f"context.l10n.{key}({m.group(1)})"
        return match.group(0)

    text = re.sub(
        r"'(?P<key>[a-zA-Z0-9_]+)'\.tr\(\s*namedArgs:\s*\{(?P<args>[^}]+)\}\s*\)",
        named_repl,
        text,
    )

    def simple_repl(match: re.Match[str]) -> str:
        key = match.group(1)
        key = KEY_RENAMES.get(key, key)
        return f"context.l10n.{key}"

    text = re.sub(r"'([a-zA-Z0-9_]+)'\.tr\(\)", simple_repl, text)

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        rel = str(path.relative_to(ROOT))
        if rel in SKIP_FILES:
            continue
        if migrate_file(path):
            print(f"migrated {rel}")
            changed += 1
    print(f"done: {changed} files")


if __name__ == "__main__":
    main()
