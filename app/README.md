# App

Flutter 앱 코드입니다.

현재 상태:

- 앱 이름: KorThai Words
- 패키지명/bundle id: `com.korthai.words`
- 하단 탭 구조: 학습 / 검색 / 설정
- 난이도별 학습 덱 화면
- 난이도별 단어 목록 화면
- 단어 카드 연습 화면
- 객관식 퀴즈 화면
- 퀴즈 완료 화면
- 난이도별 진행률 표시
- 단어 검색: 한국어, 태국어, 표시용 태국어, 발음, 뜻풀이
- 출처 및 라이선스 화면
- 설정 화면
- 학습 기록 초기화
- 즐겨찾기
- 오답노트
- 로컬 저장: 즐겨찾기/오답노트 유지
- `assets/data/words_beginner.json`, `words_intermediate.json`, `words_advanced.json` 번들 데이터 사용
- 앱 아이콘/스플래시 생성 스크립트: `/Users/jwlee/study1/thaiwordapp/scripts/generate_app_icons.py`
- 난이도별 단어 asset 패키징 스크립트: `/Users/jwlee/study1/thaiwordapp/scripts/package_level_assets.py`

즐겨찾기와 오답노트는 `shared_preferences`로 로컬 저장된다.

## Run

Flutter 설치 후:

```sh
cd /Users/jwlee/study1/thaiwordapp/app
flutter pub get
flutter run
```

검증:

```sh
flutter analyze
flutter test
```

아이콘/스플래시 재생성:

```sh
cd /Users/jwlee/study1/thaiwordapp
python3 scripts/generate_app_icons.py
```

## Update Word Assets

초급 seed query 기반 기존 파이프라인:

```sh
python3 scripts/build_beginner_data.py
```

API 호출 없이 기존 수집 데이터를 다시 분류/동기화:

```sh
python3 scripts/build_beginner_data.py --skip-fetch
```

난이도별 미러 데이터를 앱 asset으로 패키징:

```sh
cd /Users/jwlee/study1/thaiwordapp
python3 scripts/build_all_levels_data.py
```
