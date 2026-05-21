#!/usr/bin/env python3
"""Generate a lightweight quality report for level-based app assets."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATA_DIR = ROOT / "data" / "processed"
DEFAULT_REPORT = DEFAULT_DATA_DIR / "level_quality_report.md"
LEVELS = {
    "beginner": "초급",
    "intermediate": "중급",
    "advanced": "고급",
}
GRAMMAR_POS = {
    "감탄사",
    "관형사",
    "보조 동사",
    "보조 형용사",
    "의존 명사",
}
HANGUL_RE = re.compile(r"^[가-힣]+$")


def clean(value: object) -> str:
    return str(value or "").strip()


def load_words(path: Path) -> list[dict[str, object]]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array.")
    return [item for item in data if isinstance(item, dict)]


def issue_reasons(word: dict[str, object]) -> list[str]:
    korean = clean(word.get("korean"))
    thai = clean(word.get("thai"))
    thai_short = clean(word.get("thaiShort"))
    pos = clean(word.get("partOfSpeechKo"))
    definition = clean(word.get("definitionKo"))
    reasons: list[str] = []

    if len(korean) == 1:
        reasons.append("single_syllable")
    if not HANGUL_RE.match(korean):
        reasons.append("non_plain_hangul")
    if pos in GRAMMAR_POS:
        reasons.append("grammar_pos")
    if "..." in thai or "..." in thai_short or "..." in definition:
        reasons.append("ellipsis")
    if len(thai_short) > 36:
        reasons.append("long_label")
    if len(definition) > 90:
        reasons.append("long_definition")
    if not clean(word.get("pronunciation")):
        reasons.append("missing_pronunciation")
    return reasons


def render_sample(word: dict[str, object], reasons: list[str]) -> str:
    target_code = clean(word.get("targetCode"))
    korean = clean(word.get("korean"))
    pos = clean(word.get("partOfSpeechKo"))
    thai_short = clean(word.get("thaiShort") or word.get("thai"))
    definition = clean(word.get("definitionKo"))
    if len(definition) > 72:
        definition = definition[:69] + "..."
    return (
        f"| {target_code} | {korean} | {pos} | {thai_short} | "
        f"{definition} | {', '.join(reasons)} |"
    )


def write_report(path: Path, words_by_level: dict[str, list[dict[str, object]]]) -> None:
    lines = [
        "# Level Quality Report",
        "",
        "앱 asset에 들어간 난이도별 단어의 자동 점검 리포트입니다.",
        "이 리포트는 수동 검수 우선순위를 잡기 위한 힌트이며, 자동 제외 판정은 아닙니다.",
        "카테고리는 현재 앱의 주 학습 축이 아니므로 품질 경고에 포함하지 않습니다.",
        "",
        "## Summary",
        "",
        "| level | words | flagged | top flags |",
        "| --- | ---: | ---: | --- |",
    ]

    flagged_by_level: dict[str, list[tuple[dict[str, object], list[str]]]] = {}
    counters_by_level: dict[str, Counter[str]] = {}

    for level, words in words_by_level.items():
        flagged: list[tuple[dict[str, object], list[str]]] = []
        counter: Counter[str] = Counter()
        for word in words:
            reasons = issue_reasons(word)
            if reasons:
                flagged.append((word, reasons))
                counter.update(reasons)

        flagged_by_level[level] = flagged
        counters_by_level[level] = counter
        top_flags = ", ".join(f"{key}:{count}" for key, count in counter.most_common(5))
        lines.append(
            f"| {level} | {len(words)} | {len(flagged)} | {top_flags or '-'} |"
        )

    lines.append("")
    lines.append("## Samples")
    lines.append("")

    for level, flagged in flagged_by_level.items():
        lines.extend([
            f"### {level}",
            "",
            "| targetCode | korean | pos | thaiShort | definitionKo | flags |",
            "| --- | --- | --- | --- | --- | --- |",
        ])
        for word, reasons in flagged[:30]:
            lines.append(render_sample(word, reasons))
        if not flagged:
            lines.append("| - | - | - | - | - | - |")
        lines.append("")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Report quality hints for level assets.")
    parser.add_argument("--data-dir", default=str(DEFAULT_DATA_DIR))
    parser.add_argument("--report", default=str(DEFAULT_REPORT))
    args = parser.parse_args()

    data_dir = Path(args.data_dir)
    words_by_level = {
        level: load_words(data_dir / f"krdict_words_{level}_app.json")
        for level in LEVELS
    }
    report_path = Path(args.report)
    write_report(report_path, words_by_level)
    print(f"Saved quality report to {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
