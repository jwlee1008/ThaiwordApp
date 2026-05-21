# TODO

## Phase 1: Foundation

- [ ] 앱 기술 스택 확정: Flutter 또는 React Native
- [ ] 국립국어원 한국어기초사전 Open API 키 발급
- [ ] API 샘플 호출 테스트
- [x] 단어 데이터 스키마 초안 작성
- [x] 카테고리 체계 1차 초안 작성
- [x] 원천 데이터 수집 스크립트 초안 작성
- [x] 원천 데이터 라이선스/출처 표시 방식 초안 작성

## Phase 2: Data Pipeline

- [x] 초급 단어 수집 1차: 296개
- [ ] 초급 단어 1,000개 이상 확장
- [ ] 중급 단어 1,500개 이상 수집: 현재 앱용 99개
- [ ] 고급 단어 1,500개 이상 수집
- [x] Krdict 전체 미러 수집 스크립트 작성
- [ ] Krdict 전체 미러 smoke test 실행: `KRDICT_API_KEY` 필요
- [x] Krdict seed-query 미러 1차 수집
- [x] 난이도별 앱 asset 패키징 스크립트 작성
- [x] 난이도별 앱 asset 1차 생성
- [x] 난이도별 seed-query 미러 수집 완료: 앱용 448개
- [x] 난이도별 빌드/검증 통합 스크립트 작성
- [x] 난이도별 자동 품질 리포트 생성
- [ ] Krdict 전체 미러 1차 수집
- [ ] 공식 통계 대비 수집 커버리지 리포트 생성
- [x] 난이도별 seed query 파일 분리: beginner/intermediate/advanced
- [x] 난이도별 빌드 스크립트 통합
- [ ] 태국어 번역 필드 확인
- [ ] 중복 단어 정리
- [ ] 동형어/다의어 표시 정책 확정
- [x] 초급 seed query 목록 작성
- [x] 배치 수집 스크립트 작성
- [x] 초급 seed query 250개 이상 확장
- [x] 앱 asset 갱신 자동화
- [x] 초급 데이터 빌드 파이프라인 작성
- [x] 검수 리포트 생성
- [x] 검수 override 구조 작성
- [x] 긴 태국어 라벨 축약 필드 생성
- [ ] 카테고리 자동 분류
- [x] 카테고리 규칙 기반 1차 분류 스크립트 작성
- [ ] LLM으로 쉬운 예문 초안 생성
- [ ] LLM으로 퀴즈 오답 보기 초안 생성
- [ ] 로컬 LLM 보강 결과 검증 리포트 생성
- [x] 검증 스크립트 초안 작성
- [x] LLM 분류/보강 규칙 문서 작성
- [x] 앱용 난이도별 JSON 패키지 생성
- [ ] 데이터 품질 샘플 검수: 난이도별 최소 100개
- [x] 중급/고급 seed query를 초급 seed와 분리
- [ ] 중급/고급 동형어 뜻 검수 후 앱 잠금 해제
- [ ] 국립국어원 출처/라이선스 문구 최종 확인

## Phase 3: MVP App

- [x] Flutter 앱 뼈대 작성
- [x] 앱 asset 데이터 연결
- [x] 단어 목록 화면 초안
- [x] 카테고리 선택 화면 초안
- [x] 단어 카드 연습 화면 초안
- [x] 카드 넘김 시 다음 단어 뜻 순간 노출 방지
- [x] Flutter analyze 통과
- [x] Flutter widget test 통과
- [ ] 로컬 기기/시뮬레이터에서 앱 실행 확인
- [x] 객관식 퀴즈 화면 초안
- [x] 오답노트 초안
- [x] 즐겨찾기 초안
- [x] 로컬 학습 기록 저장
- [x] 퀴즈 완료 화면
- [x] 카테고리별 진행률 표시
- [x] 학습 첫 화면을 난이도별 덱 구조로 정리
- [x] 단어 검색
- [x] 출처 및 라이선스 화면
- [x] 설정 화면
- [x] 학습 기록 초기화
- [x] 하단 탭 구조

## Phase 4: Release Prep

- [x] 앱 표시 이름 확정: KorThai Words
- [x] Android applicationId/namespace 설정: com.korthai.words
- [x] iOS/macOS bundle identifier 설정: com.korthai.words
- [x] Android/iOS/macOS 앱 아이콘 생성
- [x] Android/iOS 스플래시 기본 화면 설정
- [x] Android release signing 스캐폴딩
- [x] Android adaptive icon 설정
- [x] 개인정보 처리방침 초안 작성
- [x] Play Store 설명문 초안 작성
- [ ] Android SDK 설치 후 Android 기기/에뮬레이터 빌드 확인
- [ ] Android release signing 설정
- [ ] 스토어 등록용 스크린샷/설명문 작성

## Phase 5: Later

- [ ] 로그인
- [ ] 서버 백업
- [ ] 단어 업데이트 서버
- [ ] 관리자 페이지
- [ ] 유료 단어팩
- [ ] 발음 오디오
- [ ] 푸시 복습 알림
