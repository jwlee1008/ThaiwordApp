# Krdict API Guide

국립국어원 한국어기초사전 Open API 사용 메모입니다.

## Official Pages

- 한국어기초사전 Open API: https://krdict.korean.go.kr/eng/openApi/openApiInfo
- 태국어 페이지: https://krdict.korean.go.kr/tha/openApi/openApiInfo
- 저작권 정책: https://krdict.korean.go.kr/eng/kboardPolicy/copyRightTermsInfo

## Get API Key

1. 한국어기초사전 Open API 페이지로 이동한다.
2. `Application for open API use` 메뉴에서 신청한다.
3. 발급받은 key는 로컬 환경변수로만 관리한다.
4. 키를 Git에 커밋하지 않는다.

예시:

```sh
export KRDICT_API_KEY="발급받은키"
```

또는 프로젝트 루트의 `.env`에 저장한다. `.env`는 Git에 커밋하지 않는다.

```sh
KRDICT_API_KEY=발급받은키
```

## Search Endpoint

```text
https://krdict.korean.go.kr/api/search
```

주요 파라미터:

- `key`: API 인증키
- `q`: 검색어
- `start`: 시작 번호
- `num`: 결과 수, 10~100
- `sort`: `dict` 또는 `popular`
- `translated`: 다국어 번역 사용 여부, `y`
- `trans_lang`: 태국어는 `8`
- `advanced`: 상세 검색 사용 여부, `y`
- `level`: `level1`, `level2`, `level3`
- `pos`: 품사 필터

## Example Calls

태국어 번역 포함, `나무` 검색:

```sh
curl "https://krdict.korean.go.kr/api/search?key=$KRDICT_API_KEY&q=%EB%82%98%EB%AC%B4&translated=y&trans_lang=8"
```

초급 단어 검색 예시:

```sh
curl "https://krdict.korean.go.kr/api/search?key=$KRDICT_API_KEY&q=%EA%B0%80&advanced=y&level=level1&translated=y&trans_lang=8&num=100"
```

주의: API는 XML을 반환한다. 스크립트에서 XML 파서를 사용해서 JSON으로 변환한다.

## Suggested Script Behavior

현재 `scripts/fetch_krdict.py` 초안이 준비되어 있다.

입력:

- 검색어 또는 초성/음절 목록
- 난이도
- 저장 경로

출력:

- `data/sources/krdict_raw_*.xml`
- `data/processed/krdict_words_*.json`

검증:

- API 키 누락 시 중단
- 응답이 error XML이면 실패 처리
- `target_code` 기준 중복 제거
- 태국어 번역 없는 항목은 별도 파일로 분리
- 같은 표제어/품사가 여러 번 나오는 경우는 동형어일 수 있으므로 경고로 처리

## Current Script

샘플 실행:

```sh
python3 scripts/fetch_krdict.py --query 나무 --level beginner --max-pages 1
```

결과 검증:

```sh
python3 scripts/validate_words.py data/processed/krdict_words_beginner_나무.json
```

저장된 원본 XML을 다시 파싱:

```sh
python3 scripts/fetch_krdict.py --from-xml data/sources/krdict_raw_beginner_나무_1.xml --output data/processed/krdict_words_beginner_나무.json
```

Seed 목록을 이용해 여러 단어를 한 번에 수집:

```sh
python3 scripts/fetch_batch_krdict.py --queries data/seed_queries_beginner.txt --level beginner --max-pages 1
python3 scripts/validate_words.py data/processed/krdict_words_beginner_seed.json
```

초급 데이터 전체 빌드:

```sh
python3 scripts/build_beginner_data.py
```

이미 수집된 JSON만 다시 분류하고 앱 asset으로 복사:

```sh
python3 scripts/build_beginner_data.py --skip-fetch
```

샌드박스 환경에서 `python3 -m py_compile`은 macOS Python 캐시 경로 권한 때문에 실패할 수 있다. 문법 확인은 아래처럼 캐시 생성을 끄고 실행한다.

```sh
python3 -B scripts/fetch_krdict.py --help
python3 -B scripts/validate_words.py --help
```

## Troubleshooting

### `Krdict API error 020: Unregistered key`

API 서버가 현재 키를 등록된 인증키로 인식하지 못했다는 뜻이다.

확인할 것:

1. `KRDICT_API_KEY`에 실제 발급 키를 넣었는지 확인한다.
2. 신청 번호, 이메일, 비밀번호, 설명 문구를 넣은 것은 아닌지 확인한다.
3. 키 앞뒤에 따옴표, 공백, 줄바꿈이 섞이지 않았는지 확인한다.
4. 새 터미널을 열었다면 `export KRDICT_API_KEY=...`를 다시 실행한다.
5. 키 발급 직후라면 잠시 뒤 다시 시도한다.

키 길이만 확인하고 싶을 때:

```sh
python3 -c 'import os; print(len(os.environ.get("KRDICT_API_KEY", "")))'
```

키 값 일부가 들어갔는지 확인하고 싶을 때:

```sh
python3 -c 'import os; k=os.environ.get("KRDICT_API_KEY",""); print(k[:4], "...", k[-4:], len(k))'
```
