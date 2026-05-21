#!/usr/bin/env python3
"""Fetch multiple Krdict queries and merge entries into one JSON file."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

from env_utils import load_dotenv
from fetch_krdict import PROCESSED_DIR, fetch_pages, save_json


ROOT = Path(__file__).resolve().parents[1]


def read_queries(path: Path) -> list[str]:
    queries: list[str] = []
    seen: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        value = line.strip()
        if value and not value.startswith("#") and value not in seen:
            queries.append(value)
            seen.add(value)
    return queries


def merge_entries(entries: list[dict[str, object]]) -> list[dict[str, object]]:
    merged: dict[str, dict[str, object]] = {}
    for entry in entries:
        target_code = str(entry.get("targetCode", "")).strip()
        if target_code:
            merged[target_code] = entry
    return sorted(merged.values(), key=lambda item: (str(item.get("korean", "")), str(item.get("targetCode", ""))))


def write_report(path: Path, query_counts: dict[str, int], total: int) -> None:
    lines = ["# Krdict Batch Fetch Report", "", f"Total unique words: {total}", "", "## Query Counts", ""]
    for query, count in query_counts.items():
        lines.append(f"- {query}: {count}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    load_dotenv(ROOT / ".env")

    parser = argparse.ArgumentParser(description="Fetch many Krdict queries with Thai translations.")
    parser.add_argument("--queries", default=str(ROOT / "data" / "seed_queries_beginner.txt"))
    parser.add_argument("--level", choices=["beginner", "intermediate", "advanced"], default="beginner")
    parser.add_argument("--max-pages", type=int, default=1)
    parser.add_argument("--delay", type=float, default=0.4)
    parser.add_argument("--output", default=str(PROCESSED_DIR / "krdict_words_beginner_seed.json"))
    parser.add_argument("--report", default=str(PROCESSED_DIR / "krdict_words_beginner_seed_report.md"))
    args = parser.parse_args()

    api_key = os.environ.get("KRDICT_API_KEY")
    if not api_key:
        print("Missing KRDICT_API_KEY. See docs/KRDICT_API.md.", file=sys.stderr)
        return 2

    queries = read_queries(Path(args.queries))
    if not queries:
        print(f"No queries found in {args.queries}", file=sys.stderr)
        return 2

    all_entries: list[dict[str, object]] = []
    query_counts: dict[str, int] = {}

    for index, query in enumerate(queries, start=1):
        print(f"[{index}/{len(queries)}] Fetching {query}")
        entries = fetch_pages(api_key, query, args.level, args.max_pages, args.delay)
        query_counts[query] = len(entries)
        all_entries.extend(entries)
        time.sleep(args.delay)

    merged = merge_entries(all_entries)
    save_json(Path(args.output), merged)
    write_report(Path(args.report), query_counts, len(merged))
    print(f"Saved {len(merged)} unique entries to {args.output}")
    print(f"Saved report to {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
