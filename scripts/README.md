# Scripts

데이터 수집, 정제, 검증 자동화 스크립트를 둡니다.

예정 스크립트:

- `fetch_krdict.py`: 국립국어원 API에서 단어 가져오기
- `fetch_batch_krdict.py`: seed query 목록을 돌면서 단어를 대량 수집하고 중복 제거
- `classify_categories_rule_based.py`: 한국어 표제어/정의 기반 규칙으로 앱 카테고리 초안 분류
- `sync_app_assets.py`: 정제/분류된 단어 데이터를 Flutter asset으로 복사
- `build_beginner_data.py`: 수집, 분류, 검증, 앱 asset 동기화를 한 번에 실행
- `review_words.py`: 동형어, 긴 번역, 다의어 등 검수 리포트 생성
- `filter_reviewed_words.py`: 검수 제외/카테고리 강제 지정 후 앱용 JSON 생성
- `normalize_words`: XML/JSON 원천 데이터를 앱 스키마로 정규화
- `classify_categories`: 카테고리 자동 분류
- `validate_words.py`: 중복, 누락, 품질 검증
- `build_app_db`: 앱에 넣을 SQLite 또는 JSON 생성
