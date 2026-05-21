#!/usr/bin/env python3
"""Validate processed word JSON files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


REQUIRED_FIELDS = ["id", "source", "korean", "thai", "reviewStatus"]


def load_words(path: Path) -> list[dict[str, object]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError("Word file must be a JSON array.")
    return data


def validate(words: list[dict[str, object]]) -> tuple[list[str], list[str]]:
    issues: list[str] = []
    warnings: list[str] = []
    seen_ids: set[str] = set()
    seen_pairs: dict[tuple[str, str], str] = {}

    for index, word in enumerate(words):
        label = f"item[{index}]"
        for field in REQUIRED_FIELDS:
            if not str(word.get(field, "")).strip():
                issues.append(f"{label}: missing {field}")

        word_id = str(word.get("id", "")).strip()
        if word_id:
            if word_id in seen_ids:
                issues.append(f"{label}: duplicate id {word_id}")
            seen_ids.add(word_id)

        pair = (str(word.get("korean", "")).strip(), str(word.get("partOfSpeechKo", "")).strip())
        if pair[0]:
            if pair in seen_pairs:
                warnings.append(
                    f"{label}: same korean/pos pair {pair[0]} / {pair[1]} "
                    f"also appears as {seen_pairs[pair]}"
                )
            else:
                seen_pairs[pair] = label

    return issues, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate processed word JSON.")
    parser.add_argument("path")
    args = parser.parse_args()

    words = load_words(Path(args.path))
    issues, warnings = validate(words)
    for warning in warnings:
        print(f"WARNING: {warning}")
    if issues:
        for issue in issues:
            print(f"ERROR: {issue}")
        return 1

    print(f"OK: {len(words)} words, {len(warnings)} warnings")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
