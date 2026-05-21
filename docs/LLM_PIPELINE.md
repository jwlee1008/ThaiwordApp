# LLM Data Pipeline

로컬 LLM 또는 Codex를 단어 데이터 보강에 사용할 때의 규칙입니다.

## Principle

LLM은 원천 데이터를 만들지 않는다. 원천 데이터는 국립국어원 API 등 출처가 있는 데이터에서 가져오고, LLM은 분류와 보강만 한다.

## Category Classification Input

```json
{
  "id": "krdict_32750",
  "korean": "나무",
  "thai": "ต้นไม้",
  "partOfSpeechKo": "명사",
  "levelKo": "초급",
  "definitionKo": "단단한 줄기에 가지와 잎이 달린, 여러 해 동안 자라는 식물.",
  "sourceCategories": ["동식물 > 식물류"]
}
```

## Category Classification Output

```json
{
  "id": "krdict_32750",
  "categories": ["weather_seasons"],
  "tags": ["nature", "plant"],
  "confidence": 0.82,
  "needsHumanReview": false,
  "reason": "자연과 식물 관련 초급 명사"
}
```

## Prompt Template

```text
You classify Korean vocabulary for a Thai learner's Korean word practice app.

Use only these category IDs:
{category_ids}

Rules:
- Return JSON only.
- Choose 1 to 3 categories.
- Do not invent new categories.
- Use tags in English snake_case.
- Set needsHumanReview=true if the word is ambiguous, culturally sensitive, or translation seems incomplete.
- Do not change the source word or translation.

Input word:
{word_json}
```

## Enrichment Output

LLM 보강 결과는 원본 필드를 덮어쓰지 않고 별도 필드에 저장한다.

```json
{
  "id": "krdict_32750",
  "learnerExampleKo": "집 앞에 나무가 있어요.",
  "learnerExampleTh": "หน้าบ้านมีต้นไม้",
  "quiz": {
    "type": "multiple_choice_ko_to_th",
    "answer": "ต้นไม้",
    "distractors": ["ดอกไม้", "ภูเขา", "น้ำ"]
  },
  "reviewStatus": "llm_enriched"
}
```

## Quality Checks

- 태국어가 비어 있으면 앱 DB에 넣지 않는다.
- 카테고리가 비어 있으면 검수 대상으로 분리한다.
- 객관식 보기는 정답과 너무 비슷하거나 동일하면 안 된다.
- 예문은 초급 단어에는 짧고 일상적인 문장으로 제한한다.
- LLM 생성 태국어는 최종본이 아니라 검수 대상이다.

## Current Non-LLM Baseline

LLM을 쓰기 전에 `scripts/classify_categories_rule_based.py`로 1차 규칙 분류를 한다.

```sh
python3 scripts/classify_categories_rule_based.py
python3 scripts/validate_words.py data/processed/krdict_words_beginner_seed_classified.json
```

규칙 분류 결과에서 `needsHumanReview=true`인 항목을 먼저 사람이 확인하고, 그 다음 LLM 분류/보강으로 넘어간다.
