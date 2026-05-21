#!/usr/bin/env python3
"""Build an advanced mirror by merging level seed data with saved raw XML."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from fetch_krdict import parse_entries


ROOT = Path(__file__).resolve().parents[1]
BASE_MIRROR_DIR = ROOT / "data" / "mirror" / "krdict" / "level_seed_queries"
OUTPUT_DIR = ROOT / "data" / "mirror" / "krdict" / "advanced_augmented"
SOURCE_DIR = ROOT / "data" / "sources"
LEVELS_TO_COPY = ("beginner", "intermediate")


def load_json(path: Path) -> list[dict[str, object]]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array.")
    return [item for item in data if isinstance(item, dict)]


def save_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def entry_key(entry: dict[str, object]) -> str:
    return str(entry.get("targetCode") or entry.get("id") or "").strip()


def main() -> int:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for level in LEVELS_TO_COPY:
        words = load_json(BASE_MIRROR_DIR / f"krdict_mirror_{level}.json")
        save_json(OUTPUT_DIR / f"krdict_mirror_{level}.json", words)

    entries_by_key: dict[str, dict[str, object]] = {}
    base_advanced = load_json(BASE_MIRROR_DIR / "krdict_mirror_advanced.json")
    for entry in base_advanced:
        key = entry_key(entry)
        if key:
            entries_by_key[key] = entry

    parsed_files = 0
    for path in sorted(SOURCE_DIR.glob("krdict_raw_advanced_*.xml")):
        try:
            entries, _total = parse_entries(path.read_text(encoding="utf-8"))
        except Exception as exc:
            print(f"WARN: failed to parse {path}: {exc}", file=sys.stderr)
            continue

        parsed_files += 1
        for entry in entries:
            if str(entry.get("levelKo", "")).strip() != "고급":
                continue
            key = entry_key(entry)
            if key:
                entries_by_key[key] = entry

    advanced = sorted(
        entries_by_key.values(),
        key=lambda item: (str(item.get("korean", "")), str(item.get("targetCode", ""))),
    )
    save_json(OUTPUT_DIR / "krdict_mirror_advanced.json", advanced)

    lines = [
        "# Advanced Augmented Mirror",
        "",
        f"- source base advanced: {len(base_advanced)}",
        f"- parsed raw advanced xml files: {parsed_files}",
        f"- merged advanced entries: {len(advanced)}",
    ]
    (OUTPUT_DIR / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
