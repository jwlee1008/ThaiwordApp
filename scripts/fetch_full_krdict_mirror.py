#!/usr/bin/env python3
"""Build a resumable local mirror of Krdict search results.

The Krdict search API requires a query, so a full mirror is collected by
walking a query set, filtering by level, and deduplicating by target_code.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from dataclasses import dataclass
from pathlib import Path

from env_utils import load_dotenv
from fetch_krdict import fetch_pages_with_count, save_json


ROOT = Path(__file__).resolve().parents[1]
MIRROR_DIR = ROOT / "data" / "mirror" / "krdict"
LEVELS = ("beginner", "intermediate", "advanced")
DEFAULT_SEED_QUERY_FILE = ROOT / "data" / "seed_queries_beginner.txt"
DEFAULT_LEVEL_QUERY_FILES = {
    "beginner": ROOT / "data" / "seed_queries_beginner.txt",
    "intermediate": ROOT / "data" / "seed_queries_intermediate.txt",
    "advanced": ROOT / "data" / "seed_queries_advanced.txt",
}
COMMON_SINGLE_SYLLABLES = [
    "가",
    "나",
    "다",
    "라",
    "마",
    "바",
    "사",
    "아",
    "자",
    "차",
    "카",
    "타",
    "파",
    "하",
]


@dataclass(frozen=True)
class FetchJob:
    level: str
    query: str


def read_json(path: Path, default: object) -> object:
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_query_file(path: Path) -> list[str]:
    queries: list[str] = []
    seen: set[str] = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        value = line.strip()
        if value and not value.startswith("#") and value not in seen:
            queries.append(value)
            seen.add(value)
    return queries


def hangul_syllables() -> list[str]:
    return [chr(codepoint) for codepoint in range(ord("가"), ord("힣") + 1)]


def query_set(args: argparse.Namespace) -> list[str]:
    if args.query_file:
        return read_query_file(Path(args.query_file))
    if args.seed_queries:
        return read_query_file(DEFAULT_SEED_QUERY_FILE)
    if args.all_syllables:
        return hangul_syllables()
    return COMMON_SINGLE_SYLLABLES


def query_sets_by_level(args: argparse.Namespace, levels: list[str]) -> dict[str, list[str]]:
    if args.level_seed_queries:
        return {
            level: read_query_file(DEFAULT_LEVEL_QUERY_FILES[level])
            for level in levels
        }

    queries = query_set(args)
    return {level: queries for level in levels}


def mirror_namespace(args: argparse.Namespace) -> str:
    if args.namespace:
        return args.namespace
    if args.level_seed_queries:
        return "level_seed_queries"
    if args.query_file:
        return Path(args.query_file).stem
    if args.seed_queries:
        return "seed_queries"
    if args.all_syllables:
        return "all_syllables"
    return "common_syllables"


def level_set(args: argparse.Namespace) -> list[str]:
    if args.level == "all":
        return list(LEVELS)
    return [args.level]


def load_entries(path: Path) -> dict[str, dict[str, object]]:
    entries = read_json(path, [])
    if not isinstance(entries, list):
        raise ValueError(f"{path} must contain a JSON array.")

    merged: dict[str, dict[str, object]] = {}
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        target_code = str(entry.get("targetCode", "")).strip()
        if target_code:
            merged[target_code] = entry
    return merged


def sorted_entries(entries: dict[str, dict[str, object]]) -> list[dict[str, object]]:
    return sorted(
        entries.values(),
        key=lambda item: (
            str(item.get("levelKo", "")),
            str(item.get("korean", "")),
            str(item.get("targetCode", "")),
        ),
    )


def load_done(checkpoint_path: Path) -> dict[str, int]:
    data = read_json(checkpoint_path, {"done": []})
    if not isinstance(data, dict):
        return {}

    pages_by_job = data.get("pagesByJob")
    if isinstance(pages_by_job, dict):
        return {
            str(job_id): int(pages)
            for job_id, pages in pages_by_job.items()
            if str(pages).isdigit()
        }

    # Backward compatibility with the original checkpoint format.
    done = data.get("done", [])
    if isinstance(done, list):
        return {str(item): 1 for item in done}
    return {}


def save_done(checkpoint_path: Path, pages_by_job: dict[str, int]) -> None:
    write_json(
        checkpoint_path,
        {
            "done": sorted(pages_by_job),
            "pagesByJob": dict(sorted(pages_by_job.items())),
        },
    )


def write_report(
    path: Path,
    entries_by_level: dict[str, dict[str, dict[str, object]]],
    pages_by_job: dict[str, int],
) -> None:
    lines = [
        "# Krdict Full Mirror Report",
        "",
        f"Completed jobs: {len(pages_by_job)}",
        f"Fetched pages: {sum(pages_by_job.values())}",
        "",
        "## Entries By Level",
        "",
    ]
    total = 0
    for level in LEVELS:
        count = len(entries_by_level.get(level, {}))
        total += count
        lines.append(f"- {level}: {count}")
    lines.append(f"- total unique by level buckets: {total}")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_jobs(
    levels: list[str],
    queries_by_level: dict[str, list[str]],
    query_limit: int | None,
) -> list[FetchJob]:
    jobs: list[FetchJob] = []
    for level in levels:
        queries = queries_by_level[level]
        selected_queries = queries[:query_limit] if query_limit is not None else queries
        jobs.extend(FetchJob(level=level, query=query) for query in selected_queries)
    return jobs


def main() -> int:
    load_dotenv(ROOT / ".env")

    parser = argparse.ArgumentParser(description="Fetch a resumable full-ish Krdict local mirror.")
    parser.add_argument("--level", choices=["all", *LEVELS], default="all")
    parser.add_argument("--query-file", help="Optional query file. Defaults to a small smoke-test query set.")
    parser.add_argument("--seed-queries", action="store_true", help=f"Use {DEFAULT_SEED_QUERY_FILE}.")
    parser.add_argument(
        "--level-seed-queries",
        action="store_true",
        help="Use data/seed_queries_{beginner,intermediate,advanced}.txt per level.",
    )
    parser.add_argument("--all-syllables", action="store_true", help="Use every Hangul syllable as a query.")
    parser.add_argument(
        "--allow-rare-syllables",
        action="store_true",
        help="Allow --all-syllables. This is usually inefficient and intended only for experiments.",
    )
    parser.add_argument("--namespace", help="Mirror namespace under data/mirror/krdict/.")
    parser.add_argument("--query-limit", type=int, help="Limit query count per level for smoke tests.")
    parser.add_argument("--max-pages", type=int, default=10, help="API pages per query. 10 reaches start=901.")
    parser.add_argument("--delay", type=float, default=0.25)
    parser.add_argument("--daily-call-budget", type=int, default=1000)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--reset", action="store_true", help="Clear checkpoint before running.")
    args = parser.parse_args()

    if args.all_syllables and not args.allow_rare_syllables:
        print(
            "--all-syllables walks every Unicode Hangul syllable, including rare forms such as 꽰/꿧. "
            "Use curated seed query files for app data expansion, or pass --allow-rare-syllables "
            "only for experiments.",
            file=sys.stderr,
        )
        return 2

    levels = level_set(args)
    queries_by_level = query_sets_by_level(args, levels)
    jobs = make_jobs(levels, queries_by_level, args.query_limit)

    namespace = mirror_namespace(args)
    mirror_dir = MIRROR_DIR / namespace
    checkpoint_path = mirror_dir / "checkpoint.json"
    report_path = mirror_dir / "report.md"

    if args.dry_run:
        estimated_max_calls = len(jobs) * args.max_pages
        print(f"Levels: {', '.join(levels)}")
        for level in levels:
            query_count = len(queries_by_level[level])
            if args.query_limit is not None:
                query_count = min(query_count, args.query_limit)
            print(f"Queries for {level}: {query_count}")
        print(f"Jobs: {len(jobs)}")
        print(f"Max API calls if every query fills all pages: {estimated_max_calls}")
        print(f"Daily call budget: {args.daily_call_budget}")
        print("No API calls made.")
        return 0

    api_key = os.environ.get("KRDICT_API_KEY")
    if not api_key:
        print("Missing KRDICT_API_KEY. See docs/KRDICT_API.md.", file=sys.stderr)
        return 2

    if args.reset and checkpoint_path.exists():
        checkpoint_path.unlink()

    pages_by_job = load_done(checkpoint_path)
    entries_by_level = {
        level: load_entries(mirror_dir / f"krdict_mirror_{level}.json")
        for level in LEVELS
    }

    calls_used = 0
    for index, job in enumerate(jobs, start=1):
        job_id = f"{job.level}:{job.query}"
        already_fetched_pages = pages_by_job.get(job_id, 0)
        if already_fetched_pages >= args.max_pages:
            continue
        if calls_used >= args.daily_call_budget:
            print(f"Stopped at daily call budget {args.daily_call_budget}. Resume with the same command.")
            break

        remaining_budget = args.daily_call_budget - calls_used
        max_pages = min(args.max_pages, remaining_budget)
        if already_fetched_pages:
            print(
                f"[{index}/{len(jobs)}] {job.level} {job.query} "
                f"(refresh max_pages={max_pages}, had={already_fetched_pages})"
            )
        else:
            print(f"[{index}/{len(jobs)}] {job.level} {job.query} (max_pages={max_pages})")
        entries, pages_requested = fetch_pages_with_count(api_key, job.query, job.level, max_pages, args.delay)
        calls_used += pages_requested

        bucket = entries_by_level[job.level]
        for entry in entries:
            target_code = str(entry.get("targetCode", "")).strip()
            if target_code:
                bucket[target_code] = entry

        # Mark the job complete for this max_pages setting even when the API
        # returned fewer pages, otherwise empty/short queries are retried forever.
        pages_by_job[job_id] = max(already_fetched_pages, max_pages)
        save_json(mirror_dir / f"krdict_mirror_{job.level}.json", sorted_entries(bucket))
        save_done(checkpoint_path, pages_by_job)
        write_report(report_path, entries_by_level, pages_by_job)
        time.sleep(args.delay)

    write_report(report_path, entries_by_level, pages_by_job)
    print(f"Saved mirror files to {mirror_dir}")
    print(f"Saved report to {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
