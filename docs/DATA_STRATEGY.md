# Data Strategy

## Goal

태국인을 위한 한국어 단어 연습 앱에 넣을 난이도형 단어 데이터베이스를 만든다.

현재 앱의 첫 진입점은 카테고리가 아니라 `초급 / 중급 / 고급` 난이도 덱이다. 카테고리는 내부 태그와 향후 필터로 유지한다.

## Recommended Source

1차 원천은 국립국어원 한국어기초사전 Open API입니다.

장점:

- 한국어 학습자용 단어 데이터
- 태국어 번역 지원
- 초급/중급/고급 등급 지원
- 품사, 발음, 예문, 주제/상황 카테고리 제공
- Open API 제공

주의:

- 텍스트는 CC BY-SA 조건을 확인하고 출처를 표시한다.
- 오디오, 이미지, 영상 등 멀티미디어는 텍스트와 조건이 다를 수 있으므로 별도로 확인한다.
- 앱 안에 출처 및 라이선스 페이지를 만든다.

## Data Flow

```text
Krdict API
-> data/sources/raw_krdict_*.xml or json
-> parse/normalize
-> data/processed/words_normalized.json
-> category classification
-> LLM enrichment
-> validation
-> app bundled database
```

현재 자동화:

```text
data/seed_queries_beginner.txt
-> scripts/fetch_batch_krdict.py
-> scripts/classify_categories_rule_based.py
-> scripts/review_words.py
-> scripts/filter_reviewed_words.py
-> scripts/validate_words.py
-> scripts/sync_app_assets.py
```

한 번에 실행:

```sh
python3 scripts/build_beginner_data.py
```

## Word Schema Draft

```json
{
  "id": "krdict_32750",
  "source": "krdict",
  "sourceUrl": "https://krdict.korean.go.kr",
  "korean": "나무",
  "thai": "ต้นไม้",
  "thaiShort": "ต้นไม้",
  "pronunciation": "나무",
  "partOfSpeech": "noun",
  "level": "beginner",
  "categories": ["자연", "일상"],
  "tags": ["plant"],
  "exampleKo": "집 앞에 나무가 있어요.",
  "exampleTh": "หน้าบ้านมีต้นไม้",
  "distractors": ["꽃", "물", "산"],
  "reviewStatus": "source_imported"
}
```

## Review Overrides

검수에서 제외하거나 카테고리를 강제로 지정할 항목은 `data/review_overrides.json`에 기록한다.

```json
{
  "excludeTargetCodes": ["12345"],
  "forceCategories": {
    "32750": ["weather_seasons", "topik_beginner"]
  }
}
```

앱 UI에는 원본 `thai` 대신 짧은 표시용 `thaiShort`를 우선 사용한다. 원본 번역은 데이터에 그대로 보존한다.

## Category Draft

- 인사/소개
- 숫자/시간/날짜
- 가족/사람
- 음식/식당
- 교통/길찾기
- 학교생활
- 직장생활
- 쇼핑
- 병원/건강
- 집/생활용품
- 감정/성격
- 날씨/계절
- 여행
- 한국문화
- TOPIK 초급
- TOPIK 중급

## LLM Use

LLM이 해도 되는 일:

- 단어 카테고리 분류
- 비슷한 단어 묶기
- 쉬운 한국어 예문 초안 생성
- 태국어 예문 번역 초안 생성
- 객관식 오답 보기 생성
- 태그 생성

LLM에게 맡기면 위험한 일:

- 출처 없는 단어 대량 생성
- 태국어 번역 최종본 확정
- 라이선스 판단
- 검증 없이 앱 DB에 바로 반영
