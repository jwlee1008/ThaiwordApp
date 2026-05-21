#!/usr/bin/env python3
"""Package and validate all level-based vocabulary assets."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEVELS = ("beginner", "intermediate", "advanced")


def run_step(command: list[str]) -> None:
    print("$ " + " ".join(command))
    subprocess.run(command, cwd=ROOT, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Package and validate all level-based vocabulary assets.")
    parser.add_argument(
        "--mirror-dir",
        help="Mirror directory to package. Defaults to package_level_assets.py default.",
    )
    args = parser.parse_args()

    package_command = [sys.executable, "-B", "scripts/package_level_assets.py"]
    if args.mirror_dir:
        package_command.extend(["--mirror-dir", args.mirror_dir])

    run_step(package_command)
    run_step([sys.executable, "-B", "scripts/report_level_quality.py"])
    for level in LEVELS:
        run_step([
            sys.executable,
            "-B",
            "scripts/validate_words.py",
            f"data/processed/krdict_words_{level}_app.json",
        ])
    print("All level data assets are packaged and valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
