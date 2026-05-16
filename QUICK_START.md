# Resumate — Quick Start Guide 🚀

## 🎯 What You Need to Do

### 1. Add 4 GitHub Secrets (One-Time Setup)

Go to: `https://github.com/YOUR_USERNAME/resumate/settings/secrets/actions`

Click **"New repository secret"** for each:

| Secret Name | Secret Value |
|------------|--------------|
| `AZURE_OPENAI_ENDPOINT` | Your Azure endpoint (e.g., `https://my-resource.openai.azure.com/`) |
| `AZURE_OPENAI_API_KEY` | Your Azure OpenAI API key |
| `AZURE_OPENAI_API_VERSION` | `2024-12-01-preview` |
| `AZURE_DEPLOYMENT_NAME` | Your deployment name (e.g., `gpt-4-turbo`) |

### 2. Push Your Code

```bash
cd D:\testing\resumate
git add .
git commit -m "Add Azure OpenAI integration + GitHub Actions"
git push origin main
```

### 3. Watch the Build

- Go to **Actions** tab on GitHub
- See the "Build Android APK" workflow running
- Wait ~5-8 minutes for Android build

### 4. Download Your App

- Click the completed workflow run
- Scroll to **Artifacts** section
- Download: `resumate-release-apk` 
- Extract and install the APK on Android

---

## 📱 Test Locally (Development)

Configure your credentials in `.vscode/launch.json`, then:

```bash
flutter run
```

Or use VS Code "Run and Debug" → "Resumate (Azure OpenAI)" configuration.

---

## 🎨 What's Inside

Your Resumate app has **everything complete**:

✅ **Resume Parsing** — AI extracts data from text/PDF  
✅ **Website Generation** — AI builds complete portfolio site  
✅ **AI Chat** — Conversational assistant with resume context  
✅ **Deployment** — Deploy to Vercel/Netlify/Cloudflare/GitHub Pages  
✅ **Website Preview** — Live preview with device frames  
✅ **Code IDE** — Edit HTML/CSS/JS with syntax highlighting  
✅ **Native UI** — Polished Material 3 with smooth animations  

---

## 🔑 Keys Format (For GitHub Secrets)

Add your Azure OpenAI credentials in this format:

```
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key-here
AZURE_OPENAI_API_VERSION=2024-12-01-preview
AZURE_DEPLOYMENT_NAME=your-deployment-name
```

Get these values from Azure Portal → Your OpenAI Resource → Keys and Endpoint

---

## ✨ You're Done!

Once secrets are added and code is pushed, GitHub Actions will automatically build:
- ✅ **Android APK** (ready to install on any Android device)

Fast builds in ~5-8 minutes — every push builds automatically! 🎉
