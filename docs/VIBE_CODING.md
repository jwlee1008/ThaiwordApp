# Vibe Coding Collaboration Guide

이 문서는 Codex와 이어서 작업할 때 맥락이 끊기지 않게 하기 위한 협업 규칙입니다.

## How We Work

1. 결정한 내용은 `docs/DECISIONS.md`에 짧게 남긴다.
2. 할 일은 `docs/TODO.md`에 저장한다.
3. 데이터 출처와 라이선스는 `docs/DATA_STRATEGY.md`에 기록한다.
4. API 사용법과 키 발급 절차는 `docs/KRDICT_API.md`에 유지한다.
5. LLM 데이터 보강 규칙은 `docs/LLM_PIPELINE.md`에 유지한다.
6. 새 폴더를 만들면 해당 폴더에 `README.md`를 둬서 목적을 설명한다.

## Prompt Pattern

Codex에게 일을 시킬 때는 아래처럼 말하면 좋다.

```text
docs/TODO.md 기준으로 다음 작업 진행해줘.
이번에는 국립국어원 API에서 초급 단어를 가져와 data/sources에 저장하는 스크립트부터 만들어줘.
기존 docs의 결정사항은 유지해줘.
```

또는:

```text
지금 구조를 읽고 다음 MVP 작업을 이어서 해줘.
데이터 라이선스와 출처 표시는 반드시 지켜줘.
```

## Folder Rule

- `docs/`: 사람과 AI가 같이 읽는 설명 문서
- `data/sources/`: 외부 원천에서 받은 원본 데이터
- `data/processed/`: 앱에 넣기 전 정제된 데이터
- `scripts/`: 사람이 실행하는 자동화 도구
- `app/`: 실제 모바일 앱
- `backend/`: 서버 기능이 필요해진 뒤 사용

## Data Rule

LLM은 단어의 원천이 아니라 보조 도구로 쓴다.

- 원천: 국립국어원 API 등 출처가 명확한 데이터
- LLM 역할: 카테고리 분류, 태국인용 설명 초안, 예문 초안, 퀴즈 보기 생성
- 검증: 중복, 품사, 난이도, 태국어 번역, 출처 표시

## Keep Context Small

작업을 시작할 때 Codex가 먼저 읽으면 좋은 파일:

1. `README.md`
2. `docs/TODO.md`
3. `docs/DECISIONS.md`
4. 현재 작업과 관련된 `docs/*.md`
