#!/usr/bin/env python3
"""Generate a human review report for processed vocabulary data."""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "data" / "processed" / "krdict_words_beginner_seed_classified.json"
DEFAULT_FETCH_REPORT = ROOT / "data" / "processed" / "krdict_words_beginner_seed_report.md"
DEFAULT_OUTPUT = ROOT / "data" / "processed" / "krdict_words_beginner_review_report.md"


def load_words(path: Path) -> list[dict[str, object]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError("Input must be a JSON array.")
    return data


def clean(value: object) -> str:
    return str(value or "").replace("\n", " ").strip()


def word_label(word: dict[str, object]) -> str:
    korean = clean(word.get("korean"))
    thai = clean(word.get("thai"))
    pos = clean(word.get("partOfSpeechKo"))
    target = clean(word.get("targetCode"))
    return f"{korean} / {thai} / {pos} / {target}"


def collect_zero_result_queries(fetch_report_path: Path) -> list[str]:
    if not fetch_report_path.exists():
        return []

    zero_queries = []
    in_counts = False
    for line in fetch_report_path.read_text(encoding="utf-8").splitlines():
        if line.strip() == "## Query Counts":
            in_counts = True
            continue
        if not in_counts or not line.startswith("- "):
            continue
        name, _, count = line[2:].partition(":")
        if count.strip() == "0":
            zero_queries.append(name.strip())
    return zero_queries


def build_report(words: list[dict[str, object]], zero_queries: list[str]) -> str:
    by_pair: dict[tuple[str, str], list[dict[str, object]]] = defaultdict(list)
    for word in words:
        by_pair[(clean(word.get("korean")), clean(word.get("partOfSpeechKo")))].append(word)

    homographs = {pair: items for pair, items in by_pair.items() if len(items) > 1}
    no_thai = [word for word in words if not clean(word.get("thai"))]
    no_definition = [word for word in words if not clean(word.get("definitionKo"))]
    long_thai = [word for word in words if len(clean(word.get("thai"))) > 45]
    many_senses = [
        word for word in words
        if len(word.get("definitionKoCandidates", [])) >= 4
        or len(word.get("thaiCandidates", [])) >= 4
    ]
    low_confidence = [
        word for word in words
        if float(word.get("categoryConfidence", 0) or 0) < 0.7
    ]

    category_counts: dict[str, int] = defaultdict(int)
    for word in words:
        for category in word.get("categories", []):
            category_counts[str(category)] += 1

    lines = [
        "# Beginner Word Review Report",
        "",
        f"Total words: {len(words)}",
        f"Zero-result seed queries: {len(zero_queries)}",
        f"Homograph groups: {len(homographs)}",
        f"Missing Thai: {len(no_thai)}",
        f"Missing Korean definition: {len(no_definition)}",
        f"Long Thai labels: {len(long_thai)}",
        f"Many-sense words: {len(many_senses)}",
        f"Low category confidence: {len(low_confidence)}",
        "",
        "## Category Counts",
        "",
    ]
    for category, count in sorted(category_counts.items()):
        lines.append(f"- {category}: {count}")

    lines.extend(["", "## Zero-Result Seed Queries", ""])
    if zero_queries:
        lines.extend(f"- {query}" for query in zero_queries)
    else:
        lines.append("- None")

    lines.extend(["", "## Homographs To Review", ""])
    if homographs:
        for (korean, pos), items in sorted(homographs.items()):
            lines.append(f"### {korean} / {pos}")
            for word in items:
                lines.append(f"- {word_label(word)}: {clean(word.get('definitionKo'))}")
            lines.append("")
    else:
        lines.append("- None")

    def add_section(title: str, items: list[dict[str, object]]) -> None:
        lines.extend(["", f"## {title}", ""])
        if items:
            for word in items:
                lines.append(f"- {word_label(word)}: {clean(word.get('definitionKo'))}")
        else:
            lines.append("- None")

    add_section("Long Thai Labels", long_thai)
    add_section("Many-Sense Words", many_senses)
    add_section("Low Category Confidence", low_confidence)
    add_section("Missing Thai", no_thai)
    add_section("Missing Korean Definition", no_definition)

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate vocabulary review report.")
    parser.add_argument("--input", default=str(DEFAULT_INPUT))
    parser.add_argument("--fetch-report", default=str(DEFAULT_FETCH_REPORT))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    words = load_words(Path(args.input))
    zero_queries = collect_zero_result_queries(Path(args.fetch_report))
    report = build_report(words, zero_queries)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(report, encoding="utf-8")
    print(f"Saved review report to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
