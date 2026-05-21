# Thai Korean Word App

태국인을 위한 한국어 단어 연습 앱입니다.

초기 방향은 로컬 우선 앱입니다. 단어 데이터는 검증 가능한 원천에서 가져오고, 카테고리 분류와 예문/퀴즈 보강에는 LLM을 보조 도구로 사용합니다.

## Project Shape

- `app/`: Flutter 또는 React Native 앱 코드가 들어갈 자리
- `backend/`: 나중에 로그인, 백업, 단어 업데이트 서버가 필요할 때 사용
- `data/`: 단어 원천 데이터, 가공 데이터, 앱에 넣을 최종 DB
- `docs/`: 기획, 의사결정, 협업 규칙, API 사용법
- `scripts/`: 데이터 수집/정제/검증 스크립트

## Current Recommendation

- 앱: Flutter
- 저장소: 로컬 SQLite 계열
- 단어 원천: 국립국어원 한국어기초사전 Open API
- 데이터 생성 방식: 원천 데이터 수집 -> 카테고리 분류 -> LLM 보강 -> 검증 -> 앱 DB 패키징

먼저 [docs/VIBE_CODING.md](docs/VIBE_CODING.md)와 [docs/TODO.md](docs/TODO.md)를 보면 됩니다.

## Next Commands

API 키를 받은 뒤:

```sh
export KRDICT_API_KEY="발급받은키"
python3 scripts/fetch_krdict.py --query 나무 --level beginner --max-pages 1
python3 scripts/validate_words.py data/processed/krdict_words_beginner_나무.json
```

사용자가 직접 해야 할 일은 [docs/USER_ACTIONS.md](docs/USER_ACTIONS.md)에 따로 정리되어 있습니다.

## App Preview

Flutter SDK 설치 후:

```sh
cd /Users/jwlee/study1/thaiwordapp/app
flutter create .
flutter pub get
flutter run
```
