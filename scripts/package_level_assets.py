#!/usr/bin/env python3
"""Package mirrored Krdict data into level-based Flutter assets."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from filter_reviewed_words import shorten_thai_label


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MIRROR_DIR = ROOT / "data" / "mirror" / "krdict" / "seed_queries"
PROCESSED_DIR = ROOT / "data" / "processed"
APP_ASSET_DIR = ROOT / "app" / "assets" / "data"
LEVELS = {
    "beginner": "초급",
    "intermediate": "중급",
    "advanced": "고급",
}
EXCLUDED_POS = {"접사", "품사 없음"}


def load_words(path: Path) -> list[dict[str, object]]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array.")
    return [item for item in data if isinstance(item, dict)]


def save_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def clean(value: object) -> str:
    return str(value or "").strip()


def has_displayable_shape(word: dict[str, object]) -> bool:
    korean = clean(word.get("korean"))
    pos = clean(word.get("partOfSpeechKo"))
    if not korean or not clean(word.get("thai")):
        return False
    if "-" in korean:
        return False
    if pos in EXCLUDED_POS:
        return False
    return True


def display_key(word: dict[str, object]) -> tuple[str, str]:
    return clean(word.get("korean")), clean(word.get("partOfSpeechKo"))


def normalize_word(word: dict[str, object], level_ko: str) -> dict[str, object]:
    updated = dict(word)
    updated["levelKo"] = clean(updated.get("levelKo")) or level_ko
    updated["thaiShort"] = shorten_thai_label(updated.get("thai"))
    updated.setdefault("categories", [])
    updated.setdefault("tags", [])
    updated.setdefault("distractors", [])
    updated["reviewStatus"] = clean(updated.get("reviewStatus")) or "mirror_packaged"
    return updated


def package_level(words: list[dict[str, object]], level_ko: str) -> tuple[list[dict[str, object]], dict[str, int]]:
    stats = {
        "raw": len(words),
        "missing_or_excluded": 0,
        "duplicate_display_pair": 0,
        "packaged": 0,
    }
    packaged: list[dict[str, object]] = []
    seen_display_keys: set[tuple[str, str]] = set()

    for word in words:
        if not has_displayable_shape(word):
            stats["missing_or_excluded"] += 1
            continue

        key = display_key(word)
        if key in seen_display_keys:
            stats["duplicate_display_pair"] += 1
            continue
        seen_display_keys.add(key)
        packaged.append(normalize_word(word, level_ko))

    packaged.sort(key=lambda item: (clean(item.get("korean")), clean(item.get("targetCode"))))
    stats["packaged"] = len(packaged)
    return packaged, stats


def write_report(path: Path, stats_by_level: dict[str, dict[str, int]]) -> None:
    lines = ["# Level Asset Package Report", ""]
    for level, stats in stats_by_level.items():
        lines.extend(
            [
                f"## {level}",
                "",
                f"- raw: {stats['raw']}",
                f"- packaged: {stats['packaged']}",
                f"- missing_or_excluded: {stats['missing_or_excluded']}",
                f"- duplicate_display_pair: {stats['duplicate_display_pair']}",
                "",
            ]
        )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Package level mirror files into app assets.")
    parser.add_argument("--mirror-dir", default=str(DEFAULT_MIRROR_DIR))
    parser.add_argument("--no-sync", action="store_true", help="Only write processed files.")
    args = parser.parse_args()

    mirror_dir = Path(args.mirror_dir)
    stats_by_level: dict[str, dict[str, int]] = {}

    for level, level_ko in LEVELS.items():
        source = mirror_dir / f"krdict_mirror_{level}.json"
        words = load_words(source)
        packaged, stats = package_level(words, level_ko)
        stats_by_level[level] = stats

        processed_path = PROCESSED_DIR / f"krdict_words_{level}_app.json"
        save_json(processed_path, packaged)

        if not args.no_sync:
            asset_path = APP_ASSET_DIR / f"words_{level}.json"
            save_json(asset_path, packaged)

    report_path = PROCESSED_DIR / "level_asset_package_report.md"
    write_report(report_path, stats_by_level)
    print(f"Saved package report to {report_path}")
    if not args.no_sync:
        print(f"Synced level assets to {APP_ASSET_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
