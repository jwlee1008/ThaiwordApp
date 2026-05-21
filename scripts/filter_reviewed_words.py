#!/usr/bin/env python3
"""Apply review overrides before syncing app assets."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "data" / "processed" / "krdict_words_beginner_seed_classified.json"
DEFAULT_OVERRIDES = ROOT / "data" / "review_overrides.json"
DEFAULT_OUTPUT = ROOT / "data" / "processed" / "krdict_words_beginner_app.json"


def load_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def shorten_thai_label(value: object, max_length: int = 42) -> str:
    text = str(value or "").strip()
    if len(text) <= max_length:
        return text

    parts = [part.strip() for part in text.split(",") if part.strip()]
    if parts:
        shortened = ", ".join(parts[:2])
        if len(shortened) <= max_length:
            return shortened
        return parts[0]

    return text[:max_length].rstrip() + "..."


def main() -> int:
    parser = argparse.ArgumentParser(description="Filter reviewed words for app assets.")
    parser.add_argument("--input", default=str(DEFAULT_INPUT))
    parser.add_argument("--overrides", default=str(DEFAULT_OVERRIDES))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    words = load_json(Path(args.input))
    overrides = load_json(Path(args.overrides))
    if not isinstance(words, list):
        raise ValueError("Input must be a JSON array.")
    if not isinstance(overrides, dict):
        raise ValueError("Overrides must be a JSON object.")

    excluded = set(str(code) for code in overrides.get("excludeTargetCodes", []))
    force_categories = overrides.get("forceCategories", {})
    if not isinstance(force_categories, dict):
        force_categories = {}

    filtered = []
    for word in words:
        if not isinstance(word, dict):
            continue
        target_code = str(word.get("targetCode", ""))
        if target_code in excluded:
            continue
        updated = dict(word)
        if target_code in force_categories:
            updated["categories"] = force_categories[target_code]
            updated["reviewStatus"] = "review_override"
        updated["thaiShort"] = shorten_thai_label(updated.get("thai"))
        filtered.append(updated)

    save_json(Path(args.output), filtered)
    print(f"Saved {len(filtered)} reviewed words to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
