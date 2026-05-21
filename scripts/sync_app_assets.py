#!/usr/bin/env python3
"""Copy processed vocabulary data into Flutter app assets."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_WORDS = ROOT / "data" / "processed" / "krdict_words_beginner_seed_classified.json"
DEFAULT_CATEGORIES = ROOT / "data" / "categories.json"
APP_ASSET_DIR = ROOT / "app" / "assets" / "data"


def validate_json_array(path: Path) -> int:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array.")
    return len(data)


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync processed data into Flutter assets.")
    parser.add_argument("--words", default=str(DEFAULT_WORDS))
    parser.add_argument("--categories", default=str(DEFAULT_CATEGORIES))
    args = parser.parse_args()

    words_path = Path(args.words)
    categories_path = Path(args.categories)
    word_count = validate_json_array(words_path)
    category_count = validate_json_array(categories_path)

    APP_ASSET_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(words_path, APP_ASSET_DIR / "words_beginner.json")
    shutil.copyfile(categories_path, APP_ASSET_DIR / "categories.json")

    print(f"Synced {word_count} words and {category_count} categories to {APP_ASSET_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
