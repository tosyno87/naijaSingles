#!/usr/bin/env python3
"""
Scan Dart sources for competitor brands and sloppy placeholders that appear
inside string literals only (comments and identifiers are ignored).

Invoked by scripts/pre_release_check.sh.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Word boundaries avoid path/identifier fragments (e.g. hinge_profile_card.dart).
BRAND_RE = re.compile(
    r"\bHinge\b|\bTinder\b|\bBumble\b|\bOkCupid\b|\bCoffee Meets Bagel\b|"
    r"\bMatch\.com\b|\bGrindr\b|\bBadoo\b",
    re.IGNORECASE,
)

PLACEHOLDER_RE = re.compile(
    r"(TODO.*FIXME|FIXME.*TODO|HACK.*ship|lorem ipsum)",
    re.IGNORECASE,
)


def _ident_char(c: str) -> bool:
    return c.isalnum() or c == "_"


def _line_of(s: str, idx: int) -> int:
    return s.count("\n", 0, idx) + 1


def _skip_line_comment(s: str, i: int) -> int:
    i += 2
    while i < len(s) and s[i] != "\n":
        i += 1
    return i


def _skip_block_comment(s: str, i: int) -> int:
    i += 2
    while i + 1 < len(s) and not (s[i] == "*" and s[i + 1] == "/"):
        i += 1
    return min(i + 2, len(s))


def _consume_escape(s: str, i: int) -> int:
    """i points to backslash in a non-raw string."""
    if i + 1 >= len(s):
        return i + 1
    nxt = s[i + 1]
    if nxt in "'\"\\":
        return i + 2
    if nxt in "nrtbvf":
        return i + 2
    if nxt == "\n":
        return i + 2
    if nxt == "u" and i + 2 < len(s) and s[i + 2] == "{":
        j = i + 3
        while j < len(s) and s[j] != "}":
            j += 1
        return min(j + 1, len(s))
    if nxt == "u" and i + 2 < len(s):
        return min(i + 6, len(s))
    if nxt == "x" and i + 2 < len(s):
        return min(i + 4, len(s))
    return i + 2


def _skip_balanced_braces(s: str, i: int) -> int:
    """i is first char inside '${'. Skip until matching closing '}' for interpolation."""
    depth = 1
    while i < len(s) and depth > 0:
        if s[i] == "/" and i + 1 < len(s):
            if s[i + 1] == "/":
                i = _skip_line_comment(s, i)
                continue
            if s[i + 1] == "*":
                i = _skip_block_comment(s, i)
                continue
        inner = _try_skip_string(s, i)
        if inner is not None:
            i = inner
            continue
        if s[i] == "{":
            depth += 1
        elif s[i] == "}":
            depth -= 1
        i += 1
    return i


def _skip_interpolation(s: str, i: int, raw: bool) -> int:
    """i points to '$' inside string."""
    if raw or i + 1 >= len(s):
        return i + 1
    nxt = s[i + 1]
    if nxt == "$":
        return i + 2
    if nxt == "{":
        return _skip_balanced_braces(s, i + 2)
    if nxt == "_" or nxt.isalpha():
        j = i + 2
        while j < len(s) and _ident_char(s[j]):
            j += 1
        return j
    return i + 1


def _try_skip_string(s: str, i: int) -> int | None:
    """If s[i] starts a string, return index after closing quote; else None."""
    bodies = _string_literal_bodies(s, i)
    if bodies is None:
        return None
    _, end = bodies
    return end


def _string_literal_bodies(s: str, i: int) -> tuple[list[tuple[int, str]], int] | None:
    """
    If s[i] begins a string literal, return (list of (line, text_slice), end_index).
    text_slice is the raw substring inside quotes for pattern search.
    """
    n = len(s)
    if i >= n:
        return None

    start_i = i
    raw = False
    if s[i] == "r" and (i == 0 or not _ident_char(s[i - 1])) and i + 1 < n and s[i + 1] in "'\"":
        raw = True
        i += 1

    triple = None
    if i + 2 < n:
        t = s[i : i + 3]
        if t in ("'''", '"""'):
            triple = t[0]

    pieces: list[tuple[int, str]] = []

    if triple is not None:
        close = triple * 3
        if raw:
            if not s.startswith(("r'''", 'r"""'), start_i):
                return None
            i = start_i + 4
        else:
            i = start_i + 3
        body_start = i
        while i < n:
            if s.startswith(close, i):
                piece = s[body_start:i]
                if piece:
                    pieces.append((_line_of(s, body_start), piece))
                return (pieces, i + 3)
            if not raw and s[i] == "\\" and triple == '"':
                i = _consume_escape(s, i)
                continue
            if not raw and s[i] == "$":
                inner = s[body_start:i]
                if inner:
                    pieces.append((_line_of(s, body_start), inner))
                i = _skip_interpolation(s, i, raw=False)
                body_start = i
                continue
            i += 1
        return (pieces, n)

    if i < n and s[i] not in "'\"":
        return None

    delim = s[i]
    line0 = _line_of(s, i)
    i += 1
    body_start = i
    while i < n:
        c = s[i]
        if not raw and c == "\\":
            i = _consume_escape(s, i)
            continue
        if c == delim:
            inner = s[body_start:i]
            if inner:
                pieces.append((line0, inner))
            return (pieces, i + 1)
        if not raw and c == "$":
            inner = s[body_start:i]
            if inner:
                pieces.append((_line_of(s, body_start), inner))
            i = _skip_interpolation(s, i, raw=False)
            body_start = i
            continue
        i += 1
    return (pieces, n)


def _scan_file(path: Path) -> tuple[list[tuple[int, str]], list[tuple[int, str]]]:
    """Returns (brand_rows, placeholder_rows) as (line, match)."""
    s = path.read_text(encoding="utf-8")
    brand: list[tuple[int, str]] = []
    placeholder: list[tuple[int, str]] = []
    i = 0
    n = len(s)
    while i < n:
        if s[i] == "/" and i + 1 < n:
            if s[i + 1] == "/":
                i = _skip_line_comment(s, i)
                continue
            if s[i + 1] == "*":
                i = _skip_block_comment(s, i)
                continue

        got = _string_literal_bodies(s, i)
        if got is not None:
            pieces, j = got
            for line, piece in pieces:
                bm = BRAND_RE.search(piece)
                if bm:
                    brand.append((line, bm.group(0)))
                pm = PLACEHOLDER_RE.search(piece)
                if pm:
                    placeholder.append((line, pm.group(0)))
            i = j
            continue

        i += 1

    return brand, placeholder


def main() -> int:
    lib = Path(__file__).resolve().parent.parent / "lib"
    if not lib.is_dir():
        print(f"FAIL: missing lib directory: {lib}", file=sys.stderr)
        return 1

    brand_all: list[tuple[Path, int, str]] = []
    ph_all: list[tuple[Path, int, str]] = []

    for path in sorted(lib.rglob("*.dart")):
        b, p = _scan_file(path)
        for line, m in b:
            brand_all.append((path, line, m))
        for line, m in p:
            ph_all.append((path, line, m))

    if brand_all:
        print("FAIL: Competitor brand names found inside string literals:")
        print("")
        for path, line, m in brand_all:
            rel = path.relative_to(lib.parent)
            print(f"{rel}:{line}: {m}")
        print("")
        return 1

    if ph_all:
        print("WARN: Possible placeholder text inside string literals:")
        print("")
        for path, line, m in ph_all:
            rel = path.relative_to(lib.parent)
            print(f"{rel}:{line}: {m}")
        print("")
        print("OK: No competitor brand references in Dart string literals.")
        return 0

    print("All clear — no competitor brand references in Dart string literals.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
