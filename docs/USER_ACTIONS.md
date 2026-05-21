# User Actions

사용자가 직접 해야 하는 일입니다.

## Required Now

1. Flutter SDK를 설치한다.
   - https://docs.flutter.dev/get-started/install/macos
   - 설치 후 `flutter doctor`로 상태를 확인한다.

2. 앱 플랫폼 폴더를 생성한다.

```sh
cd /Users/jwlee/study1/thaiwordapp/app
flutter create .
flutter pub get
flutter run
```

현재 이 Mac에서는 Flutter 앱 코드 검증과 macOS 빌드는 가능하다. Android 출시는 아직 SDK 설정이 필요하다.

- macOS/iOS 실행: Xcode 전체 설치 후 아래 실행

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

- Android 실행: Android Studio에서 Android SDK와 에뮬레이터 설치
- Web 실행: Google Chrome 설치 또는 `CHROME_EXECUTABLE` 설정

3. 국립국어원 한국어기초사전 Open API 키를 신청한다.
   - https://krdict.korean.go.kr/eng/openApi/openApiInfo
   - 메뉴: `Application for open API use`

4. 발급받은 키를 로컬 환경변수로 설정한다.

```sh
export KRDICT_API_KEY="발급받은키"
```

키는 신청 번호나 계정 정보가 아니라 API 인증키여야 한다. API 문서 기준으로 32자리 16진수 형태의 키가 필요하다.

5. 키 설정 후 샘플 수집을 실행한다.

```sh
python3 scripts/fetch_krdict.py --query 나무 --level beginner --max-pages 1
```

6. 결과 검증을 실행한다.

```sh
python3 scripts/validate_words.py data/processed/krdict_words_beginner_나무.json
```

## Product Decisions To Make

- 앱 기술 스택: Flutter 기준으로 진행 중
- 첫 출시 범위: Android 먼저인지 Android/iOS 동시인지 결정
- 첫 카테고리 5~8개를 고르기
- 앱 이름: 현재 `KorThai Words`
- 패키지명/bundle id: 현재 `com.korthai.words`
- 출처/라이선스 화면 위치: 설정 탭에 배치 완료

## Android Release Later

- Android Studio에서 Android SDK 설치
- `flutter doctor`에서 Android toolchain 통과 확인
- 릴리즈 서명용 keystore 생성
- `android/key.properties`와 Gradle release signing 설정
- 자세한 절차: `/Users/jwlee/study1/thaiwordapp/docs/ANDROID_RELEASE.md`

## Nice To Have

- 태국어 원어민 검수자 1명 확보
- TOPIK 중심인지 생활 한국어 중심인지 우선순위 결정
- 유료화 방식 결정: 광고, 광고 제거, 단어팩, 구독 중 선택
