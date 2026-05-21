# Data Expansion Plan

방대한 단어 데이터베이스를 만들기 위한 다음 작업 계획입니다.

## Goal

1차 목표는 앱 안에서 난이도별로 충분히 학습할 수 있는 데이터팩을 만드는 것입니다.

- 초급: 1,000개 이상
- 중급: 1,500개 이상
- 고급: 1,500개 이상
- 총 4,000개 이상을 1차 목표로 둔다.

## Source Policy

주 원천은 국립국어원 한국어기초사전 Open API로 유지합니다.

원칙:

- 앱 DB에 들어가는 단어는 출처가 있어야 한다.
- LLM은 단어를 새로 invent 하지 않는다.
- LLM은 예문, 태그, 퀴즈 보기, 쉬운 설명 같은 보강 작업에 사용한다.
- 태국어 번역은 원천 데이터를 우선하고, LLM 결과는 검수 전까지 보조 필드로만 둔다.

## Data Files To Add

```text
data/seed_queries_beginner.txt
data/seed_queries_intermediate.txt
data/seed_queries_advanced.txt
data/processed/krdict_words_beginner_app.json
data/processed/krdict_words_intermediate_app.json
data/processed/krdict_words_advanced_app.json
app/assets/data/words_beginner.json
app/assets/data/words_intermediate.json
app/assets/data/words_advanced.json
```

## Pipeline Tasks

1. 난이도별 seed query를 분리한다.
2. batch fetch 스크립트가 난이도별 출력 파일을 만들게 확장한다.
3. 중복 단어를 `targetCode`, `korean`, `partOfSpeechKo`, `definitionKo` 기준으로 정리한다.
4. 동형어와 다의어는 억지로 합치지 않고 별도 entry로 유지한다.
5. 태국어 번역이 비어 있거나 너무 긴 항목은 리포트로 분리한다.
6. `thaiShort`를 모든 entry에 생성한다.
7. LLM 보강은 별도 파일에 저장하고 원천 필드는 덮어쓰지 않는다.
8. 검증을 통과한 데이터만 앱 asset으로 동기화한다.

## Quality Gates

각 난이도 데이터팩은 앱 반영 전에 아래 조건을 통과해야 합니다.

- `id` 중복 없음
- `targetCode` 중복 정책 준수
- `korean`, `thai`, `levelKo`, `partOfSpeechKo` 필수
- 태국어 표시 필드가 너무 길면 `thaiShort` 존재
- 퀴즈 보기 4개 구성 가능
- 난이도별 최소 100개 샘플 수동 검수
- 출처/라이선스 표시 가능

## App Changes Needed

현재 앱은 난이도별 덱 구조로 바꿔두었으므로, 데이터팩이 추가되면 다음만 하면 됩니다.

- `pubspec.yaml`에 `words_intermediate.json`, `words_advanced.json` asset 추가
- 앱 로더가 세 파일을 모두 읽도록 변경
- 중급/고급 덱 잠금 상태 자동 해제
- 설정/출처 화면에서 난이도별 단어 수 표시

## Recommended Next Step

현재 `scripts/package_level_assets.py`가 seed-query 미러를 앱용 난이도별 JSON으로 패키징한다.

현재 1차 패키징 결과:

- 초급: 282개
- 중급: 99개
- 고급: 67개
- 합계: 448개

접사, 하이픈 표제어, 같은 한국어/품사 표시 중복은 앱 asset에서 제외한다.

`scripts/build_all_levels_data.py`는 난이도별 앱 asset 패키징과 검증을 한 번에 실행한다.
중급은 난이도별 seed-query 수집 후 99개가 확보되어 앱에서 열어 둔다.
고급은 아직 67개라 최소 기준을 넘기기 전까지 잠금 상태로 둔다.

```sh
cd /Users/jwlee/study1/thaiwordapp
python3 scripts/build_all_levels_data.py
```

빌드 과정에서 `data/processed/level_quality_report.md`도 함께 생성한다.
이 리포트는 한 글자 표제어, 문법성 품사, 말줄임표 번역, 긴 라벨 등을 모아 수동 검수 우선순위를 정하는 용도다.

난이도별 seed query 파일은 아래처럼 분리한다.

```text
data/seed_queries_beginner.txt
data/seed_queries_intermediate.txt
data/seed_queries_advanced.txt
```

수집은 `--level-seed-queries`를 권장한다.

```sh
python3 scripts/fetch_full_krdict_mirror.py \
  --level all \
  --level-seed-queries \
  --max-pages 3 \
  --daily-call-budget 2000 \
  --delay 0.2
```

수집 후 앱 asset 패키징은 아래 명령으로 진행한다.

```sh
python3 scripts/build_all_levels_data.py \
  --mirror-dir data/mirror/krdict/level_seed_queries
```

다음 구현 작업은 전체 미러 수집 후 앱 패키징까지 이어주는 상위 자동화입니다.

이 스크립트는 아래를 한 번에 실행해야 합니다.

```text
beginner/intermediate/advanced seed query 읽기
-> Krdict batch fetch
-> rule classify
-> review/filter
-> validate
-> app assets sync
-> 난이도별 리포트 생성
```
