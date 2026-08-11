#!/usr/bin/env python3
"""Validate Conventional Commits headers for pull-request titles and commits."""

from __future__ import annotations

import argparse
import re
import sys
from collections.abc import Iterable

ALLOWED_TYPES: tuple[str, ...] = (
    "build",
    "chore",
    "ci",
    "docs",
    "feat",
    "fix",
    "perf",
    "refactor",
    "revert",
    "style",
    "test",
)

_HEADER_RE = re.compile(
    r"""
    ^
    (?P<type>[A-Za-z]+)
    (?:\((?P<scope>[^)]+)\))?
    (?P<breaking>!)?
    :\ 
    (?P<description>.+?)
    \s*$
    """,
    re.VERBOSE,
)


def _validate_message(message: str) -> list[str]:
    """Return validation errors, or an empty list for a valid header."""
    header = message.splitlines()[0] if message else ""
    if not header.strip():
        return ["message is empty"]

    match = _HEADER_RE.match(header)
    if match is None:
        return [
            "header does not match '<type>(<scope>)!: <description>' "
            "(see https://www.conventionalcommits.org/en/v1.0.0/)",
        ]

    commit_type = match.group("type")
    if commit_type.lower() not in ALLOWED_TYPES:
        return [
            f"type '{commit_type}' is not allowed; "
            f"use one of: {', '.join(ALLOWED_TYPES)}",
        ]
    return []


def _safe_log_value(value: str) -> str:
    return value.encode("unicode_escape").decode("ascii")


def _iter_messages(args: argparse.Namespace) -> Iterable[str]:
    if args.stdin:
        for line in sys.stdin:
            stripped = line.rstrip("\n")
            if stripped:
                yield stripped
    else:
        yield from args.messages


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Validate Conventional Commits headers.",
    )
    parser.add_argument("messages", nargs="*")
    parser.add_argument("--stdin", action="store_true")
    args = parser.parse_args(argv)

    if not args.stdin and not args.messages:
        parser.error("provide at least one message or use --stdin")

    failures = 0
    checked = 0
    for message in _iter_messages(args):
        checked += 1
        errors = _validate_message(message)
        safe_message = _safe_log_value(message)
        if errors:
            failures += 1
            print(f"INVALID: {safe_message}", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
        else:
            print(f"OK: {safe_message}")

    if checked == 0:
        print("No messages to validate.", file=sys.stderr)
        return 1
    if failures:
        print(
            f"\n{failures} of {checked} message(s) failed Conventional "
            "Commits validation.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())