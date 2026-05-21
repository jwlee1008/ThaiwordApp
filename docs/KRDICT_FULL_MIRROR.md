# Krdict Full Mirror

Krdict 전체 원천 데이터를 로컬에 모으기 위한 작업 문서입니다.

## Why Mirror First

한국어기초사전은 공식 통계 기준 표제어 53,487개 규모입니다. 앱에 바로 전부 넣기 전에 `data/mirror/krdict/`에 원천 미러를 만들고, 앱에는 검증된 난이도별 asset만 반영합니다.

## Collection Strategy

Krdict search API는 `q`가 필수라서 전체 덤프처럼 한 번에 내려받을 수 없습니다.

따라서 아래 방식으로 수집합니다.

1. 쿼리 집합을 만든다.
2. `beginner`, `intermediate`, `advanced` 난이도별로 검색한다.
3. `targetCode` 기준으로 dedupe한다.
4. checkpoint를 저장해서 중간에 끊겨도 재개한다.
5. mirror JSON은 앱 asset과 분리한다.

## Dry Run

API 호출 없이 예상 규모만 봅니다.

```sh
cd /Users/jwlee/study1/thaiwordapp
python3 scripts/fetch_full_krdict_mirror.py --dry-run
```

기존 초급 seed query를 쿼리 후보로 쓰는 경우:

```sh
python3 scripts/fetch_full_krdict_mirror.py --seed-queries --dry-run
```

난이도별 seed query를 각각 쓰는 경우:

```sh
python3 scripts/fetch_full_krdict_mirror.py --level-seed-queries --dry-run
```

모든 한글 음절을 쿼리 후보로 쓰는 경우:

```sh
python3 scripts/fetch_full_krdict_mirror.py --all-syllables --dry-run
```

## Smoke Test

작은 쿼리 집합으로 실제 API 호출과 저장 구조만 확인합니다.

```sh
cd /Users/jwlee/study1/thaiwordapp
export KRDICT_API_KEY="발급받은키"
python3 scripts/fetch_full_krdict_mirror.py --level all --seed-queries --query-limit 3 --max-pages 1 --daily-call-budget 9
```

## Full-ish Mirror Run

하루 호출량을 제한해서 여러 번 이어서 실행합니다.

```sh
cd /Users/jwlee/study1/thaiwordapp
export KRDICT_API_KEY="발급받은키"
python3 scripts/fetch_full_krdict_mirror.py \
  --level all \
  --seed-queries \
  --max-pages 10 \
  --daily-call-budget 2000 \
  --delay 0.25
```

이 명령은 기존 초급 seed query 257개를 초급/중급/고급 전체에 적용합니다. 즉 최대 작업은 약 771개입니다.
중급/고급 품질을 높일 때는 아래처럼 난이도별 seed query를 쓰는 명령을 권장합니다.

```sh
python3 scripts/fetch_full_krdict_mirror.py \
  --level all \
  --level-seed-queries \
  --max-pages 3 \
  --daily-call-budget 2000 \
  --delay 0.2
```

결과는 `data/mirror/krdict/level_seed_queries/`에 저장됩니다.

수집 완료 후 앱 데이터로 패키징하려면:

```sh
python3 scripts/build_all_levels_data.py \
  --mirror-dir data/mirror/krdict/level_seed_queries
```

검색 범위를 더 넓히려면 모든 한글 음절을 대상으로 합니다.

```sh
python3 scripts/fetch_full_krdict_mirror.py \
  --level all \
  --all-syllables \
  --max-pages 10 \
  --daily-call-budget 2000 \
  --delay 0.25
```

결과:

```text
data/mirror/krdict/seed_queries/krdict_mirror_beginner.json
data/mirror/krdict/seed_queries/krdict_mirror_intermediate.json
data/mirror/krdict/seed_queries/krdict_mirror_advanced.json
data/mirror/krdict/seed_queries/checkpoint.json
data/mirror/krdict/seed_queries/report.md
```

수집 방식별로 namespace가 분리됩니다.

- `--seed-queries`: `data/mirror/krdict/seed_queries/`
- `--level-seed-queries`: `data/mirror/krdict/level_seed_queries/`
- `--all-syllables`: `data/mirror/krdict/all_syllables/`
- 기본 14개 음절 smoke test: `data/mirror/krdict/common_syllables/`

이렇게 분리하는 이유는 `갂`, `갃` 같은 모든 한글 음절 검색 실험 기록이 seed query 수집 리포트를 지저분하게 만들지 않도록 하기 위해서입니다.

## Resume

중간에 끊기면 같은 명령을 다시 실행하면 됩니다. 이미 끝난 작업은 `checkpoint.json`을 보고 건너뜁니다.

`checkpoint.json`은 작업별로 몇 페이지까지 가져왔는지도 저장합니다. 예를 들어 예전에 `--max-pages 1`로 실행했더라도 나중에 `--max-pages 10`으로 실행하면 같은 쿼리를 다시 보강 수집합니다.

처음부터 다시 하려면:

```sh
python3 scripts/fetch_full_krdict_mirror.py --reset --level all --seed-queries --query-limit 3 --max-pages 1 --daily-call-budget 9
```

## Important Caveat

한글 음절 검색은 실용적인 전체 수집 방법이지만, 검색 API의 동작 방식 때문에 공식 표제어 수와 1:1로 정확히 일치한다고 가정하면 안 됩니다. 수집 후 공식 통계와 비교하고 누락률을 확인해야 합니다.

## Next Pipeline Step

미러가 충분히 쌓이면 다음 스크립트를 만든다.

```text
scripts/package_level_assets.py
```

역할:

- mirror JSON 읽기
- 등급별 필수 필드 검증
- 태국어 번역 없는 항목 분리
- 앱 표시용 `thaiShort` 생성
- 난이도별 `words_*.json` asset 생성
