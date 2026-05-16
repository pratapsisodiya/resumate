# Build Instructions — Resumate

## ✅ Fixed Issues

1. **flutter_lints version error** — Changed from `^6.0.0` to `^5.0.0` (compatible with Dart SDK 3.5.0)
2. **GitHub Actions simplified** — Now only builds Android APK (faster, simpler)

---

## 🚀 GitHub Actions — Android APK Only

Your workflow now builds **only Android APK** for faster CI/CD:

- ✅ Runs on every push to `main`, `master`, or `develop`
- ✅ Builds in ~5-8 minutes (much faster than multi-platform)
- ✅ Uses Flutter 3.24.0 stable
- ✅ Injects Azure OpenAI credentials at build time
- ✅ Uploads APK artifact for 30 days
- ✅ Shows APK size in PR comments

---

## 📋 GitHub Secrets (Required)

Add these 4 secrets to your repository:

```
AZURE_OPENAI_ENDPOINT=<your-azure-endpoint>
AZURE_OPENAI_API_KEY=<your-azure-openai-api-key-here>
AZURE_OPENAI_API_VERSION=2024-12-01-preview
AZURE_DEPLOYMENT_NAME=gpt-4.1-mini
```

**Where to add:**
1. Go to: `https://github.com/YOUR_USERNAME/resumate/settings/secrets/actions`
2. Click "New repository secret"
3. Add each secret with exact name and value

---

## 📦 Download Built APK

After pushing to GitHub:

1. Go to **Actions** tab
2. Click the latest workflow run
3. Scroll to **Artifacts** section
4. Download **`resumate-release-apk`**
5. Extract the ZIP → `app-release.apk`
6. Install on Android device

---

## 🛠️ Build Manually (All Platforms)

### Android APK:
```bash
flutter build apk --release \
  --dart-define=AZURE_OPENAI_ENDPOINT=<your-azure-endpoint> \
  --dart-define=AZURE_OPENAI_API_KEY=<your-azure-openai-api-key-here> \
  --dart-define=AZURE_OPENAI_API_VERSION=2024-12-01-preview \
  --dart-define=AZURE_DEPLOYMENT_NAME=gpt-4.1-mini
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store):
```bash
flutter build appbundle --release \
  --dart-define=AZURE_OPENAI_ENDPOINT=<your-azure-endpoint> \
  --dart-define=AZURE_OPENAI_API_KEY=<your-azure-openai-api-key-here> \
  --dart-define=AZURE_OPENAI_API_VERSION=2024-12-01-preview \
  --dart-define=AZURE_DEPLOYMENT_NAME=gpt-4.1-mini
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Windows:
```bash
flutter build windows --release \
  --dart-define=AZURE_OPENAI_ENDPOINT=<your-azure-endpoint> \
  --dart-define=AZURE_OPENAI_API_KEY=<your-azure-openai-api-key-here> \
  --dart-define=AZURE_OPENAI_API_VERSION=2024-12-01-preview \
  --dart-define=AZURE_DEPLOYMENT_NAME=gpt-4.1-mini
```

Output: `build/windows/x64/runner/Release/`

### Web:
```bash
flutter build web --release \
  --dart-define=AZURE_OPENAI_ENDPOINT=<your-azure-endpoint> \
  --dart-define=AZURE_OPENAI_API_KEY=<your-azure-openai-api-key-here> \
  --dart-define=AZURE_OPENAI_API_VERSION=2024-12-01-preview \
  --dart-define=AZURE_DEPLOYMENT_NAME=gpt-4.1-mini
```

Output: `build/web/`

---

## 🧪 Run Locally (Development)

No build needed — credentials are hardcoded as defaults:

```bash
flutter run
```

Or use VS Code launch config "Resumate (Azure OpenAI)"

---

## ✅ Verification

After pushing, check:

1. **GitHub Actions tab** — workflow should be running
2. Wait ~5-8 minutes
3. Green checkmark = success
4. Download artifact
5. Test APK on Android device

---

## 🎯 What Changed

| Before | After |
|--------|-------|
| Multi-platform builds (15+ min) | Android APK only (~5-8 min) |
| flutter_lints ^6.0.0 (broken) | flutter_lints ^5.0.0 (works) |
| Complex workflow | Simple, fast workflow |
| 5 artifacts | 1 artifact (APK) |

---

## 📝 Notes

- APK size: ~40-60 MB (includes all dependencies)
- APK works on Android 5.0+ (API 21+)
- Azure credentials are embedded in the APK
- Credentials are hardcoded as defaults in code (dev convenience)
- GitHub Actions uses secrets for production builds

---

## 🔥 Ready to Go!

Your app is now ready to build on GitHub Actions:

1. ✅ Build error fixed
2. ✅ Workflow simplified
3. ✅ Faster builds (~5-8 min)
4. ✅ Just add 4 GitHub secrets
5. ✅ Push and download APK

**Next steps:** Add the 4 GitHub secrets and your APK will build automatically on every push! 🚀
