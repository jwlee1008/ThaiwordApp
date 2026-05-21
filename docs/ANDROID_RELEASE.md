# Android Release

`KorThai Words`의 Android 출시 준비 메모입니다.

## Current App Identity

- App name: `KorThai Words`
- Application ID: `com.korthai.words`
- Version: `0.1.0+1`
- Data mode: local-first bundled JSON data

## Required Local Setup

Android Studio에서 Android SDK와 에뮬레이터를 설치한 뒤 확인합니다.

```sh
cd /Users/jwlee/study1/thaiwordapp/app
flutter doctor
flutter devices
```

`flutter doctor`에서 Android toolchain이 통과해야 Android 빌드가 가능합니다.

## Release Signing

릴리즈 키는 저장소에 넣지 않습니다. 아래 명령은 로컬에서만 실행합니다.

```sh
cd /Users/jwlee/study1/thaiwordapp/app/android
keytool -genkey -v \
  -keystore release-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias korthai_words
```

그 다음 예시 파일을 복사해서 실제 비밀번호를 입력합니다.

```sh
cp key.properties.example key.properties
```

`key.properties` 예시:

```properties
storePassword=replace-with-keystore-password
keyPassword=replace-with-key-password
keyAlias=korthai_words
storeFile=../release-keystore.jks
```

`key.properties`와 `*.jks`는 `.gitignore`에 포함되어 있습니다.

## Build Commands

디버그 APK:

```sh
cd /Users/jwlee/study1/thaiwordapp/app
flutter build apk --debug
```

Play Store 제출용 App Bundle:

```sh
cd /Users/jwlee/study1/thaiwordapp/app
flutter build appbundle --release
```

서명 키가 없으면 현재 Gradle 설정은 개발 편의를 위해 debug signing으로 release 빌드를 시도합니다. Play Store 제출 전에는 반드시 `key.properties`와 `release-keystore.jks`를 설정해야 합니다.

## Pre-Submission Checklist

- [ ] Android SDK 설치 및 `flutter doctor` 통과
- [ ] 실제 Android 기기 또는 에뮬레이터 실행 확인
- [ ] `flutter build appbundle --release` 성공
- [ ] 앱 아이콘이 런처에서 선명하게 보이는지 확인
- [ ] 스플래시 화면 확인
- [ ] 설정 탭의 출처/라이선스 화면 확인
- [ ] 개인정보 처리방침 URL 준비
- [ ] Play Console 데이터 보안 설문 작성
- [ ] 스토어 스크린샷 준비
