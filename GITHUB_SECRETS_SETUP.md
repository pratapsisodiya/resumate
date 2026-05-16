# GitHub Actions Setup Guide

## 📋 GitHub Secrets to Add

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these **4 secrets** with your Azure OpenAI credentials:

### 1. `AZURE_OPENAI_ENDPOINT`
```
https://your-resource.openai.azure.com/
```
Example: `https://my-openai.openai.azure.com/`

### 2. `AZURE_OPENAI_API_KEY`
```
your-azure-openai-api-key
```
Find this in Azure Portal → Your OpenAI Resource → Keys and Endpoint

### 3. `AZURE_OPENAI_API_VERSION`
```
2024-12-01-preview
```
Use the latest API version supported by your deployment

### 4. `AZURE_DEPLOYMENT_NAME`
```
your-deployment-name
```
Example: `gpt-4`, `gpt-4-turbo`, `gpt-35-turbo`, etc.

---

## 🎯 How to Add Secrets

### Step-by-Step:

1. **Go to your GitHub repository** (e.g., `https://github.com/YOUR_USERNAME/resumate`)

2. Click **Settings** (top tab)

3. In the left sidebar, expand **Secrets and variables** → click **Actions**

4. Click **New repository secret** button

5. **For each secret above:**
   - **Name**: Copy the secret name exactly (e.g., `AZURE_OPENAI_ENDPOINT`)
   - **Secret**: Copy the value exactly
   - Click **Add secret**

6. Repeat for all 4 secrets

---

## ✅ Verify Secrets

After adding all secrets, you should see:

```
✓ AZURE_OPENAI_ENDPOINT
✓ AZURE_OPENAI_API_KEY
✓ AZURE_OPENAI_API_VERSION
✓ AZURE_DEPLOYMENT_NAME
```

---

## 🚀 How GitHub Actions Works

Once you push code to GitHub, the workflow automatically:

1. **Runs on every push** to `main`, `master`, or `develop` branch
2. **Runs on pull requests** to those branches
3. **Can be triggered manually** via "Actions" tab → "Build Resumate" → "Run workflow"

### What Gets Built:

- ✅ **Android APK** — ready to install on any Android device
- ✅ **Android App Bundle (AAB)** — ready to upload to Google Play Store
- ✅ **Windows EXE** — ready to run on Windows
- ✅ **Web Build** — ready to deploy to Vercel/Netlify/GitHub Pages
- ✅ **iOS App** — unsigned, needs macOS + Xcode to sign

### Where to Download Builds:

1. Go to **Actions** tab in GitHub
2. Click the latest successful workflow run
3. Scroll to **Artifacts** section
4. Download:
   - `resumate-android-apk` — APK file
   - `resumate-android-bundle` — AAB file
   - `resumate-windows` — Windows ZIP
   - `resumate-web` — Web build folder
   - `resumate-ios` — iOS ZIP

---

## 🔒 Security Notes

- Secrets are **encrypted** and never exposed in logs
- The `--dart-define` flags inject secrets at **build time** only
- Secrets are **not** stored in the compiled app as plain text (they're baked into the binary)
- Anyone with the APK/EXE can technically extract them (reverse engineering), but they're not visible in source code

**Production Recommendation**: Use a **separate Azure OpenAI account** for GitHub Actions with limited quota/rate limits, not your main production keys.

---

## 🛠️ Manual Build (Without GitHub Actions)

If you want to build locally with credentials:

```bash
flutter build apk --release \
  --dart-define=AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/ \
  --dart-define=AZURE_OPENAI_API_KEY=your-api-key \
  --dart-define=AZURE_OPENAI_API_VERSION=2024-12-01-preview \
  --dart-define=AZURE_DEPLOYMENT_NAME=your-deployment-name
```

Or configure VS Code launch config "Resumate (Azure OpenAI)" in `.vscode/launch.json` with your credentials.

---

## 📦 Output Files

After a successful build, you'll get:

### Android
- `app-release.apk` — Install directly on Android (40-60 MB)
- `app-release.aab` — Upload to Google Play Store (20-30 MB)

### Windows
- `resumate-windows.zip` — Contains Resumate.exe + DLLs (80-120 MB)

### Web
- `build/web/` folder — Deploy to any static host (10-20 MB)

### iOS
- `Runner.app` — Requires Xcode to sign and install (60-90 MB)

---

## 🔄 Triggering a Build

### Automatic Triggers:
- Push to `main`, `master`, or `develop`
- Create a pull request to those branches

### Manual Trigger:
1. Go to **Actions** tab
2. Click **Build Resumate** workflow
3. Click **Run workflow** dropdown
4. Select branch
5. Click **Run workflow** button

---

## 🐛 Troubleshooting

### Build fails with "Secret not found"
→ Check that all 4 secrets are added with **exact names** (case-sensitive)

### Build fails with "Azure OpenAI error"
→ Verify the API key and endpoint are correct in GitHub secrets

### APK won't install on Android
→ Enable "Install from unknown sources" in Android settings

### Windows exe is flagged by antivirus
→ This is normal for unsigned exe files. Either:
   - Add exception in antivirus
   - Codesign the exe (requires certificate)

---

## 📝 Workflow File Location

The GitHub Actions workflow is located at:
```
.github/workflows/build.yml
```

You can customize it (e.g., change Flutter version, add tests, deploy automatically).

---

## ✨ Next Steps

1. ✅ Add the 4 GitHub secrets
2. ✅ Push your code to GitHub
3. ✅ Watch the Actions tab — builds start automatically
4. ✅ Download artifacts when done
5. ✅ Test the APK on Android or EXE on Windows

Your app will build with Azure OpenAI credentials baked in! 🎉
