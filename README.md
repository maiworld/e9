# GitIgnore 캐시 삭제
git rm -r --cached .

# Model 생성
flutter pub run build_runner build

# 안드로이드 인증키 생성
keytool -genkey -v -keystore ~/${ALIAS_NAME}.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ${ALIAS_NAME} -storetype JKS

# 안드로이드 인증키 출력
keytool -list -v -alias ${ALIAS_NAME} -keystore ${ALIAS_NAME}.jks

# 스플래시 이미지 생성
flutter pub pub run flutter_native_splash:create

# 스플래시 이미지 삭제
flutter pub run flutter_native_splash:remove

# 디버그 키해시
keytool -exportcert -alias ${ALIAS_NAME} -keystore ${KEY_PATH} -storepass android -keypass android | openssl sha1 -binary | openssl base64

# 릴리즈 키해시
keytool -exportcert -alias ${ALIAS_NAME} -keystore ${KEY_PATH} | openssl sha1 -binary | openssl base64  (릴리즈 키 해시)

# 인증서 개발 버전 컴파일
keytool -list -v -alias dev -keystore /Users/hpodong/Github/filunway-app/android/app/dev.jks

# 인증서 정식 버전 컴파일
keytool -list -v -alias key -keystore /Users/hpodong/Github/filunway-app/android/app/prod.jks

# 정식 버전 앱 빌드
- appbundle
flutter clean && flutter pub get && flutter build appbundle --flavor prod -t lib/prod.dart
- apk
flutter clean && flutter pub get && flutter build apk --flavor prod -t lib/prod.dart

# 개발 버전 앱 빌드
- appbundle
flutter clean && flutter pub get && flutter build appbundle --flavor dev -t lib/dev.dart
- apk
flutter clean && flutter pub get && flutter build apk --flavor dev -t lib/dev.dart