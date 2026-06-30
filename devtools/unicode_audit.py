#!/usr/bin/env python3
"""Audit text files for hidden, bidirectional, or control Unicode characters."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys
import unicodedata

DEFAULT_PATHS = [
    ".github",
    "Project.toml",
    "README.md",
    "src",
    "test",
    "docs",
    "benchmark",
]

ALLOWED_CONTROLS = {0x09, 0x0A, 0x0D}
BIDI_CONTROL_CLASSES = {"RLE", "LRE", "RLO", "LRO", "PDF", "RLI", "LRI", "FSI", "PDI"}
EXPLICITLY_HIDDEN = {
    0x00AD,  # soft hyphen
    0x034F,  # combining grapheme joiner
    0x061C,  # arabic letter mark
    0x180E,  # mongolian vowel separator
    0x200B,  # zero width space
    0x200C,  # zero width non-joiner
    0x200D,  # zero width joiner
    0x200E,  # left-to-right mark
    0x200F,  # right-to-left mark
    0x2028,  # line separator
    0x2029,  # paragraph separator
    0x202A,  # left-to-right embedding
    0x202B,  # right-to-left embedding
    0x202C,  # pop directional formatting
    0x202D,  # left-to-right override
    0x202E,  # right-to-left override
    0x2060,  # word joiner
    0x2061,  # function application
    0x2062,  # invisible times
    0x2063,  # invisible separator
    0x2064,  # invisible plus
    0x2066,  # left-to-right isolate
    0x2067,  # right-to-left isolate
    0x2068,  # first strong isolate
    0x2069,  # pop directional isolate
    0x206A,  # inhibit symmetric swapping
    0x206B,  # activate symmetric swapping
    0x206C,  # inhibit arabic form shaping
    0x206D,  # activate arabic form shaping
    0x206E,  # national digit shapes
    0x206F,  # nominal digit shapes
    0xFE00,  # variation selector-1
    0xFE01,
    0xFE02,
    0xFE03,
    0xFE04,
    0xFE05,
    0xFE06,
    0xFE07,
    0xFE08,
    0xFE09,
    0xFE0A,
    0xFE0B,
    0xFE0C,
    0xFE0D,
    0xFE0E,  # text presentation selector
    0xFE0F,  # emoji presentation selector
    0xFEFF,  # zero width no-break space / BOM
}


def iter_files(path: Path):
    if path.is_file():
        yield path
        return
    if path.is_dir():
        for child in sorted(path.rglob("*")):
            if child.is_file():
                yield child


def classify_char(ch: str) -> str | None:
    code = ord(ch)
    category = unicodedata.category(ch)
    bidi = unicodedata.bidirectional(ch)
    if code in EXPLICITLY_HIDDEN:
        return "hidden/invisible Unicode"
    if bidi in BIDI_CONTROL_CLASSES:
        return "bidirectional Unicode control"
    if category == "Cc" and code not in ALLOWED_CONTROLS:
        return "ASCII/Unicode control character"
    if category == "Cf":
        return "Unicode format character"
    if category in {"Zl", "Zp"}:
        return "Unicode line/paragraph separator"
    if category == "Zs" and ch != " ":
        return "non-ASCII space"
    return None


def audit_file(path: Path, root: Path):
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return []

    findings = []
    for line_no, line in enumerate(text.splitlines(keepends=True), start=1):
        for col_no, ch in enumerate(line, start=1):
            reason = classify_char(ch)
            if reason is None:
                continue
            findings.append(
                (
                    str(path.relative_to(root)),
                    line_no,
                    col_no,
                    ord(ch),
                    unicodedata.name(ch, "<unnamed>"),
                    reason,
                ),
            )
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", default=DEFAULT_PATHS)
    args = parser.parse_args()

    root = Path.cwd()
    findings = []
    for raw_path in args.paths:
        path = root / raw_path
        if not path.exists():
            print(f"warning: path not found, skipping: {raw_path}", file=sys.stderr)
            continue
        for file_path in iter_files(path):
            findings.extend(audit_file(file_path, root))

    if findings:
        for relpath, line_no, col_no, codepoint, name, reason in findings:
            print(
                f"{relpath}:{line_no}:{col_no}: U+{codepoint:04X} {name} ({reason})",
                file=sys.stderr,
            )
        print(
            f"\nunicode audit failed: found {len(findings)} hidden/bidi/control character(s)",
            file=sys.stderr,
        )
        return 1

    print("unicode audit passed: no hidden/bidi/control characters found")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
