#!/usr/bin/env python3
"""Fetch Korean Basic Dictionary entries and convert them to app-friendly JSON."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

from env_utils import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "data" / "sources"
PROCESSED_DIR = ROOT / "data" / "processed"
API_URL = "https://krdict.korean.go.kr/api/search"
THAI_LANGUAGE_CODE = "8"
LEVELS = {
    "beginner": "level1",
    "intermediate": "level2",
    "advanced": "level3",
}


def text_of(node: ET.Element | None, path: str, default: str = "") -> str:
    if node is None:
        return default
    found = node.find(path)
    if found is None or found.text is None:
        return default
    return found.text.strip()


def all_texts(node: ET.Element | None, path: str) -> list[str]:
    if node is None:
        return []
    values: list[str] = []
    for found in node.findall(path):
        if found.text and found.text.strip():
            values.append(found.text.strip())
    return values


def first_text(node: ET.Element | None, paths: list[str]) -> str:
    for path in paths:
        value = text_of(node, path)
        if value:
            return value
    return ""


def request_xml(params: dict[str, str | int]) -> str:
    url = f"{API_URL}?{urllib.parse.urlencode(params)}"
    request = urllib.request.Request(url, headers={"User-Agent": "thaiwordapp-data-fetch/0.1"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def fail_on_api_error(root: ET.Element) -> None:
    if root.tag != "error":
        return
    code = text_of(root, "error_code", "unknown")
    message = text_of(root, "message", "unknown error")
    if code == "020":
        raise RuntimeError(
            "Krdict API error 020: Unregistered key. "
            "Check that KRDICT_API_KEY is the issued 32-character API key, "
            "not the application id, email, or placeholder text."
        )
    raise RuntimeError(f"Krdict API error {code}: {message}")


def parse_entry(item: ET.Element) -> dict[str, object]:
    target_code = text_of(item, "target_code")
    word_info = item.find("word_info")
    source = word_info if word_info is not None else item
    senses = source.findall("sense_info") or source.findall("sense")
    first_sense = senses[0] if senses else None

    definitions = all_texts(source, ".//sense_info/definition") or all_texts(source, ".//sense/definition")
    examples = all_texts(source, ".//example_info/example") or all_texts(source, ".//example")
    translations = all_texts(source, ".//translation_info/translation") or all_texts(source, ".//translation/trans_word")
    translation_definitions = all_texts(source, ".//translation/trans_dfn")
    categories = all_texts(source, ".//category_info/written_form")

    return {
        "id": f"krdict_{target_code}" if target_code else "",
        "source": "krdict",
        "sourceUrl": text_of(item, "link", "https://krdict.korean.go.kr"),
        "targetCode": target_code,
        "korean": first_text(source, ["word"]),
        "thai": translations[0] if translations else "",
        "thaiCandidates": translations,
        "thaiDefinition": translation_definitions[0] if translation_definitions else "",
        "thaiDefinitionCandidates": translation_definitions,
        "pronunciation": first_text(source, ["pronunciation_info/pronunciation", "pronunciation"]),
        "partOfSpeechKo": first_text(source, ["pos"]),
        "levelKo": first_text(source, ["word_grade"]),
        "sourceCategories": categories,
        "definitionKo": definitions[0] if definitions else text_of(first_sense, "definition"),
        "definitionKoCandidates": definitions,
        "exampleKo": examples[0] if examples else "",
        "exampleKoCandidates": examples,
        "categories": [],
        "tags": [],
        "distractors": [],
        "reviewStatus": "source_imported",
    }


def parse_entries(xml_text: str) -> tuple[list[dict[str, object]], int]:
    root = ET.fromstring(xml_text)
    fail_on_api_error(root)
    total_text = text_of(root, "total", "0")
    total = int(total_text) if total_text.isdigit() else 0
    entries = [parse_entry(item) for item in root.findall("item")]
    return entries, total


def save_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def save_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fetch_pages_with_count(
    api_key: str,
    query: str,
    level: str,
    max_pages: int,
    delay: float,
) -> tuple[list[dict[str, object]], int]:
    entries_by_id: dict[str, dict[str, object]] = {}
    level_param = LEVELS[level]
    pages_requested = 0

    for page in range(max_pages):
        start = page * 100 + 1
        params = {
            "key": api_key,
            "q": query,
            "start": start,
            "num": 100,
            "sort": "dict",
            "translated": "y",
            "trans_lang": THAI_LANGUAGE_CODE,
            "advanced": "y",
            "level": level_param,
        }
        xml_text = request_xml(params)
        pages_requested += 1
        raw_name = f"krdict_raw_{level}_{query}_{start}.xml"
        save_text(SOURCE_DIR / raw_name, xml_text)

        page_entries, total = parse_entries(xml_text)
        if not page_entries:
            break

        for entry in page_entries:
            target_code = str(entry.get("targetCode", ""))
            if target_code:
                entries_by_id[target_code] = entry

        if start + len(page_entries) > total:
            break
        time.sleep(delay)

    return list(entries_by_id.values()), pages_requested


def fetch_pages(api_key: str, query: str, level: str, max_pages: int, delay: float) -> list[dict[str, object]]:
    entries, _pages_requested = fetch_pages_with_count(api_key, query, level, max_pages, delay)
    return entries


def main() -> int:
    load_dotenv(ROOT / ".env")

    parser = argparse.ArgumentParser(description="Fetch Krdict words with Thai translations.")
    parser.add_argument("--query", default="가", help="Search query. Use one syllable or a word.")
    parser.add_argument("--level", choices=sorted(LEVELS), default="beginner")
    parser.add_argument("--max-pages", type=int, default=1)
    parser.add_argument("--delay", type=float, default=0.4)
    parser.add_argument("--output", help="Output JSON path.")
    parser.add_argument("--from-xml", help="Parse an existing raw XML file instead of calling the API.")
    args = parser.parse_args()

    if args.from_xml:
        xml_text = Path(args.from_xml).read_text(encoding="utf-8")
        entries, _total = parse_entries(xml_text)
    else:
        api_key = os.environ.get("KRDICT_API_KEY")
        if not api_key:
            print("Missing KRDICT_API_KEY. See docs/KRDICT_API.md.", file=sys.stderr)
            return 2
        entries = fetch_pages(api_key, args.query, args.level, args.max_pages, args.delay)

    output = Path(args.output) if args.output else PROCESSED_DIR / f"krdict_words_{args.level}_{args.query}.json"
    save_json(output, entries)
    print(f"Saved {len(entries)} entries to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
