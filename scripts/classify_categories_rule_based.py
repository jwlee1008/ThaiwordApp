#!/usr/bin/env python3
"""Assign initial app categories with simple Korean keyword rules."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = ROOT / "data" / "processed" / "krdict_words_beginner_seed.json"
DEFAULT_OUTPUT = ROOT / "data" / "processed" / "krdict_words_beginner_seed_classified.json"
DEFAULT_REPORT = ROOT / "data" / "processed" / "krdict_words_beginner_seed_classified_report.md"


CATEGORY_RULES: dict[str, dict[str, list[str]]] = {
    "greetings_intro": {
        "words": ["나", "너", "저", "우리", "여러분", "이름", "성", "나이", "나라", "한국", "태국", "외국", "말", "한국어", "태국어", "안녕", "처음", "감사", "죄송"],
        "keywords": ["말하는 사람", "자기", "가리키는 말", "국적", "소개", "이름", "언어", "인사"],
    },
    "numbers_time_dates": {
        "words": ["시간", "오늘", "내일", "어제", "지금", "나중", "아침", "점심", "저녁", "밤", "날", "일", "주", "월", "년", "요일", "월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일", "하나", "둘", "셋", "넷", "다섯", "첫째", "둘째"],
        "keywords": ["시각", "날", "하루", "오전", "오후", "밤", "기간", "때", "숫자", "순서"],
    },
    "family_people": {
        "words": ["가족", "어머니", "아버지", "엄마", "아빠", "부모", "동생", "형", "오빠", "누나", "언니", "아들", "딸", "할머니", "할아버지", "친구", "사람", "아이", "남자", "여자", "어른"],
        "keywords": ["가족", "부모", "자식", "형제", "친하게", "남성", "여성"],
    },
    "food_restaurant": {
        "words": ["음식", "밥", "물", "커피", "차", "우유", "빵", "고기", "생선", "과일", "사과", "바나나", "김치", "국", "라면", "식당", "메뉴", "주문", "맛", "배", "술", "소금", "설탕", "아침", "점심", "저녁"],
        "keywords": ["먹", "마시", "음식", "식사", "손님", "주문", "차나무", "끓인 물"],
    },
    "transport_directions": {
        "words": ["버스", "지하철", "택시", "차", "길", "역", "공항", "기차", "비행기", "자동차", "자전거", "거리", "왼쪽", "오른쪽", "앞", "뒤", "옆", "위", "아래", "안", "밖", "여기", "거기", "저기", "가다", "오다", "타다", "내리다"],
        "keywords": ["교통", "비행기", "기차", "전철", "타고", "도로", "방향", "위치"],
    },
    "school_life": {
        "words": ["학교", "학생", "선생님", "교실", "책", "공책", "연필", "펜", "책상", "의자", "칠판", "숙제", "시험", "공부", "수업", "질문", "대답", "도서관", "대학교", "학원"],
        "keywords": ["학교", "학생", "교육", "공부", "수업", "가르치"],
    },
    "work_life": {
        "words": ["회사", "일", "직장", "사무실", "회의", "직원", "사장"],
        "keywords": ["회사", "직장", "업무", "회의", "근무"],
    },
    "shopping": {
        "words": ["시장", "돈", "가게", "가격", "값", "원", "카드", "계산", "선물", "옷", "신발", "가방", "싸다", "비싸다", "사다", "팔다", "주다", "받다", "찾다", "필요"],
        "keywords": ["물건", "팔다", "파는", "가격", "돈", "시장", "가게"],
    },
    "health_hospital": {
        "words": ["병원", "약", "몸", "머리", "눈", "코", "입", "귀", "손", "발", "다리", "배", "감기", "열", "아프다", "건강", "의사", "간호사", "약국", "운동"],
        "keywords": ["병", "치료", "의사", "건강", "아프", "약", "몸"],
    },
    "home_daily_items": {
        "words": ["집", "방", "문", "창문", "부엌", "화장실", "침대", "옷", "신발", "가방", "전화", "휴대폰", "컴퓨터", "사진", "종이", "물건", "열쇠", "시계", "우산", "생활"],
        "keywords": ["사는 곳", "방", "가구", "거주"],
    },
    "emotion_personality": {
        "words": ["기분", "마음", "생각", "좋다", "싫다", "기쁘다", "슬프다", "화", "무섭다", "재미", "재미있다", "어렵다", "쉽다", "빠르다", "느리다", "친절하다", "예쁘다", "크다", "작다", "많다", "적다"],
        "keywords": ["기분", "마음", "감정", "성격", "좋아", "싫어"],
    },
    "weather_seasons": {
        "words": ["날씨", "비", "눈", "바람", "구름", "하늘", "해", "달", "별", "나무", "꽃", "산", "바다", "강", "물", "봄", "여름", "가을", "겨울", "춥다", "덥다", "따뜻하다"],
        "keywords": ["기상", "하늘", "식물", "자연", "계절"],
    },
    "travel": {
        "words": ["여행", "호텔", "예약", "관광", "지도", "여권", "공항", "바다", "산"],
        "keywords": ["여행", "관광", "예약", "공항", "숙소", "호텔"],
    },
    "korean_culture": {
        "words": ["한국", "문화", "한국문화", "노래", "영화", "드라마", "음악", "축구", "명절"],
        "keywords": ["한국", "문화", "명절", "예절", "노래", "영화"],
    },
}


TAG_RULES: list[tuple[str, list[str]]] = [
    ("person", CATEGORY_RULES["family_people"]["words"] + ["사람", "나", "너", "저", "우리"]),
    ("place", ["학교", "집", "방", "식당", "시장", "가게", "병원", "역", "공항", "회사", "호텔", "도서관"]),
    ("food_drink", CATEGORY_RULES["food_restaurant"]["words"]),
    ("transport", CATEGORY_RULES["transport_directions"]["words"]),
    ("time", CATEGORY_RULES["numbers_time_dates"]["words"]),
    ("nature", CATEGORY_RULES["weather_seasons"]["words"]),
    ("health", CATEGORY_RULES["health_hospital"]["words"]),
    ("shopping", CATEGORY_RULES["shopping"]["words"]),
]


def load_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def searchable_text(word: dict[str, object]) -> str:
    parts = [
        str(word.get("korean", "")),
        str(word.get("definitionKo", "")),
        str(word.get("thai", "")),
        str(word.get("thaiDefinition", "")),
    ]
    parts.extend(str(value) for value in word.get("definitionKoCandidates", []) if value)
    return " ".join(parts)


def classify_word(word: dict[str, object]) -> tuple[list[str], list[str], float, bool]:
    korean = str(word.get("korean", "")).strip()
    text = searchable_text(word)
    scores: dict[str, int] = {}

    for category_id, rule in CATEGORY_RULES.items():
        score = 0
        if korean in rule["words"]:
            score += 4
        for keyword in rule["keywords"]:
            if keyword and keyword in text:
                score += 1
        if score:
            scores[category_id] = score

    ranked = sorted(scores.items(), key=lambda item: (-item[1], item[0]))
    categories = [category_id for category_id, _score in ranked[:1]]
    if str(word.get("levelKo", "")) == "초급":
        categories.append("topik_beginner")

    tags = []
    for tag, words in TAG_RULES:
        if korean in words:
            tags.append(tag)

    confidence = 0.0
    if ranked:
        best = ranked[0][1]
        confidence = min(0.95, 0.35 + best * 0.12)

    needs_review = not categories or confidence < 0.55
    return categories, tags, round(confidence, 2), needs_review


def classify(words: list[dict[str, object]]) -> list[dict[str, object]]:
    classified = []
    for word in words:
        categories, tags, confidence, needs_review = classify_word(word)
        updated = dict(word)
        updated["categories"] = categories
        updated["tags"] = sorted(set(list(updated.get("tags", [])) + tags))
        updated["categoryConfidence"] = confidence
        updated["needsHumanReview"] = needs_review
        updated["reviewStatus"] = "rule_classified" if categories else "needs_category_review"
        classified.append(updated)
    return classified


def write_report(path: Path, words: list[dict[str, object]]) -> None:
    counts: dict[str, int] = {}
    review_words = []
    for word in words:
        for category_id in word.get("categories", []):
            counts[str(category_id)] = counts.get(str(category_id), 0) + 1
        if word.get("needsHumanReview"):
            review_words.append(word)

    lines = [
        "# Category Classification Report",
        "",
        f"Total words: {len(words)}",
        f"Needs review: {len(review_words)}",
        "",
        "## Category Counts",
        "",
    ]
    for category_id, count in sorted(counts.items()):
        lines.append(f"- {category_id}: {count}")

    lines.extend(["", "## Needs Human Review", ""])
    if review_words:
        for word in review_words:
            lines.append(f"- {word.get('korean')} ({word.get('id')}): {word.get('definitionKo')}")
    else:
        lines.append("- None")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Classify word categories with simple keyword rules.")
    parser.add_argument("--input", default=str(DEFAULT_INPUT))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--report", default=str(DEFAULT_REPORT))
    args = parser.parse_args()

    words = load_json(Path(args.input))
    if not isinstance(words, list):
        raise ValueError("Input must be a JSON array.")

    classified = classify(words)
    save_json(Path(args.output), classified)
    write_report(Path(args.report), classified)
    print(f"Saved {len(classified)} classified words to {args.output}")
    print(f"Saved report to {args.report}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
