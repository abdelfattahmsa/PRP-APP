# PRP System — Deployment & Publishing Guide

## Platform Support Matrix

| Platform | Status | Min Version | Build Command |
|----------|--------|-------------|---------------|
| Android | Ready | Android 5.0 (API 21) | `flutter build apk --release` |
| iOS | Ready | iOS 12.0 | `flutter build ios --release` |
| Web | Ready | Modern browsers | `flutter build web --release` |
| Windows | Ready | Windows 10+ | `flutter build windows --release` |
| macOS | Ready | macOS 10.14+ | `flutter build macos --release` |
| Linux | Ready | Ubuntu 18.04+ | `flutter build linux --release` |

---

## Android

### Build
```bash
flutter build apk --release          # APK (direct install)
flutter build appbundle --release     # AAB (Google Play)
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Signing
1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore prp-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias prp
   ```
2. Create `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=prp
   storeFile=../prp-release.jks
   ```
3. Configure `android/app/build.gradle` to use the keystore.

### Publish to Google Play Store
1. Create a [Google Play Developer account](https://play.google.com/console) — **$25 one-time fee**
2. Create a new app in Play Console
3. Upload the `.aab` file to Internal Testing → Closed Testing → Production
4. Fill in store listing (screenshots, description, privacy policy)
5. Set content rating, pricing (free), and target audience
6. Submit for review (typically 1-3 days)

**Cost: $25 one-time**

---

## iOS

### Prerequisites
- macOS with Xcode 15+ installed
- Apple Developer account

### Build
```bash
flutter build ios --release
```

### Publish to App Store
1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) — **$99/year**
2. Configure signing in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Set Bundle Identifier (e.g., `com.kyberia.prp`)
   - Enable automatic signing with your team
3. Archive and upload:
   ```bash
   flutter build ipa --release
   ```
   Or use Xcode: Product → Archive → Distribute App → App Store Connect
4. In [App Store Connect](https://appstoreconnect.apple.com):
   - Create new app
   - Fill in metadata, screenshots, description
   - Submit for review (typically 1-2 days)

**Cost: $99/year**

---

## Web

### Build
```bash
flutter build web --release
```

Output: `build/web/` directory

### Deploy Options

#### Vercel (Recommended — Free)
```bash
npm i -g vercel
cd build/web
vercel --prod
```

#### Firebase Hosting (Free tier)
```bash
npm i -g firebase-tools
firebase init hosting    # Set public dir to build/web
firebase deploy
```

#### Netlify (Free tier)
1. Drag `build/web/` folder to [netlify.com](https://netlify.com)
2. Or connect Git repo with build command: `flutter build web --release`

#### Custom Server
Copy `build/web/` contents to any static file server (Nginx, Apache, S3+CloudFront).

**Cost: Free (all options have free tiers)**

---

## Windows

### Build
```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

### Distribution Options

#### Direct Distribution (Free)
- Zip the Release folder and distribute directly
- Users run `prp_system.exe`

#### Microsoft Store
1. Register for [Microsoft Partner Center](https://partner.microsoft.com) — **$19 one-time** (individual)
2. Package as MSIX:
   ```bash
   flutter pub run msix:create
   ```
   Add to `pubspec.yaml`:
   ```yaml
   msix_config:
     display_name: PRP System
     publisher_display_name: Kyberia
     identity_name: com.kyberia.prp
     msix_version: 2.0.0.0
     logo_path: assets/icons/app_icon.png
   ```
3. Upload MSIX to Partner Center
4. Submit for certification (typically 1-3 days)

**Cost: $19 one-time (Store) or Free (direct)**

---

## macOS

### Prerequisites
- macOS machine with Xcode installed
- Apple Developer account (same as iOS)

### Build
```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/PRP System.app`

### Distribution Options

#### Direct Distribution (Free)
- Distribute the `.app` bundle directly
- For notarization (recommended): `xcrun notarytool submit`

#### Mac App Store
1. Same Apple Developer account as iOS — **$99/year** (shared)
2. Open `macos/Runner.xcworkspace` in Xcode
3. Configure signing and entitlements
4. Archive → Distribute App → App Store Connect
5. Submit for review

**Cost: $99/year (shared with iOS)**

---

## Cost Summary

| Platform | Publishing Cost | Recurring |
|----------|----------------|-----------|
| Android (Google Play) | $25 | One-time |
| iOS (App Store) | $99/year | Annual |
| macOS (Mac App Store) | $99/year | Shared with iOS |
| Windows (Microsoft Store) | $19 | One-time |
| Web | Free | — |
| **Total to publish everywhere** | **$143 first year** | **$99/year after** |

### Minimum Viable Launch Strategy
1. **Web** (free) — Deploy to Vercel immediately
2. **Android APK** (free) — Direct distribution while Play Store review pending
3. **Google Play** ($25) — Submit for broader reach
4. **iOS + macOS** ($99/year) — When ready for Apple ecosystem
5. **Windows Store** ($19) — Optional, direct `.exe` works fine

---

## Environment Variables

The app requires these Supabase credentials (already configured in `app_constants.dart`):
- `supabaseUrl` — Your Supabase project URL
- `supabaseAnonKey` — Your Supabase anonymous key

For production, consider moving these to environment variables or a `.env` file using `flutter_dotenv`.

## CI/CD (Optional)

### GitHub Actions Example
```yaml
name: Build & Deploy
on:
  push:
    branches: [main]

jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          working-directory: build/web

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```
