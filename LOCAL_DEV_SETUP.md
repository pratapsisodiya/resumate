# Local Development Setup

## 🚀 Quick Start for Local Development

Your actual Azure OpenAI credentials are stored in `.vscode/launch.local.json` (gitignored).

### To Run Locally:

1. **Open in VS Code**
2. **Press F5** or click "Run and Debug"
3. **Select**: "Resumate (Azure OpenAI - Local)"

The app will launch with your real Azure credentials already configured!

---

## 📝 Files

- `.vscode/launch.json` — Template with placeholder credentials (committed to git)
- `.vscode/launch.local.json` — Your real credentials (gitignored, never pushed)

---

## ✅ Your Credentials

Edit `.vscode/launch.local.json` and add your Azure OpenAI credentials:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Resumate (Azure OpenAI - Local)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/",
        "--dart-define=AZURE_OPENAI_API_KEY=your-api-key",
        "--dart-define=AZURE_OPENAI_API_VERSION=2024-12-01-preview",
        "--dart-define=AZURE_DEPLOYMENT_NAME=your-deployment"
      ]
    }
  ]
}
```

This file is gitignored and never pushed to GitHub.

---

## 🔒 Security

- `.vscode/launch.local.json` is in `.gitignore` — never gets pushed to GitHub
- Template file `.vscode/launch.json` has placeholder values only
- When you push code, only placeholders are shared
- Your real keys stay local

---

## 🎯 Test the App

Run the app and test:

1. **Resume Parsing**: Go to Resume tab → Add Resume → Paste text → Parse with AI
2. **Website Generation**: Go to Home → Generate Website → Select template → Watch it build
3. **AI Chat**: Home → AI Chat tile → Ask a question

All features work with your real Azure credentials! 🎉
