#!/usr/bin/env python3
"""Build beginner vocabulary data from Krdict fetch to Flutter assets."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def run_step(command: list[str]) -> None:
    print("$ " + " ".join(command))
    subprocess.run(command, cwd=ROOT, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch, classify, validate, and sync beginner data.")
    parser.add_argument("--skip-fetch", action="store_true", help="Use existing processed source JSON.")
    parser.add_argument("--max-pages", type=int, default=1)
    parser.add_argument("--delay", type=float, default=0.15)
    args = parser.parse_args()

    if not args.skip_fetch:
        run_step([
            sys.executable,
            "-B",
            "scripts/fetch_batch_krdict.py",
            "--queries",
            "data/seed_queries_beginner.txt",
            "--level",
            "beginner",
            "--max-pages",
            str(args.max_pages),
            "--delay",
            str(args.delay),
        ])

    run_step([sys.executable, "-B", "scripts/classify_categories_rule_based.py"])
    run_step([sys.executable, "-B", "scripts/review_words.py"])
    run_step([sys.executable, "-B", "scripts/filter_reviewed_words.py"])
    run_step([sys.executable, "-B", "scripts/validate_words.py", "data/processed/krdict_words_beginner_app.json"])
    run_step([sys.executable, "-B", "scripts/sync_app_assets.py", "--words", "data/processed/krdict_words_beginner_app.json"])
    print("Beginner data build complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
