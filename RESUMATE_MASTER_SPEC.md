# RESUMATE — MASTER TECHNICAL SPECIFICATION
## Flutter AI-Powered Resume → Website Generator
**Version:** 1.0.0  
**Architecture:** Clean Architecture + BLoC (flutter_bloc)  
**AI Stack:** Firebase GenKit (primary), OpenAI GPT-4o (fallback), Anthropic Claude 3.5 Sonnet (website generation)  
**Deployment Targets:** Vercel, Cloudflare Pages, Netlify, GitHub (API-based, no Git CLI)

---

## 1. EXECUTIVE OVERVIEW

Resumate is a Flutter mobile application that transforms user resumes into fully deployed, responsive personal websites. The app uses a multi-agent AI pipeline to generate modern, Tailwind-styled HTML/CSS/JS websites from structured resume data, then deploys them via platform APIs and publishes source code to GitHub without requiring local Git installation.

**Core Value Proposition:**
- User uploads/pastes resume → AI generates website → One-tap deploy to live URL
- Zero Git knowledge required
- Multi-provider deployment redundancy
- AI-powered support chat for resume optimization

---

## 2. SYSTEM ARCHITECTURE

### 2.1 High-Level Flow
```
[User Input] → [Resume Parser] → [AI Website Generator] → [Build Pipeline] → [Deploy Manager] → [Live URL]
                                    ↓
                              [GitHub Publisher]
                                    ↓
                              [Support AI Chat]
```

### 2.2 Layer Architecture (Clean Architecture + BLoC)
```
Presentation Layer (Flutter UI + BLoC)
    ├── Screens / Widgets
    ├── BLoCs (Business Logic Components)
    └── States & Events

Domain Layer (Pure Dart)
    ├── Entities (Resume, Website, Deployment, User)
    ├── Repository Interfaces
    └── Use Cases (GenerateWebsite, DeployToVercel, etc.)

Data Layer
    ├── Repositories (Implementation)
    ├── Data Sources
    │   ├── Remote (GenKit API, OpenAI, Claude, Vercel API, etc.)
    │   └── Local (Hive/SharedPreferences)
    └── Models (DTOs with JSON serialization)
```

---

## 3. STATE MANAGEMENT (BLoC PATTERN)

### 3.1 Core BLoCs

#### `ResumeBloc`
- **Events:** `LoadResume`, `ParseResume`, `UpdateSection`, `ValidateResume`
- **States:** `ResumeInitial`, `ResumeLoading`, `ResumeLoaded(Resume resume)`, `ResumeError(String message)`
- **Responsibilities:** Resume CRUD, PDF parsing, section validation

#### `WebsiteGeneratorBloc`
- **Events:** `GenerateWebsite(Resume resume, TemplateStyle style)`, `RegenerateSection(String section)`, `PreviewWebsite`, `AbortGeneration`
- **States:** `GeneratorIdle`, `GeneratorAnalyzing`, `GeneratorBuilding(String stage)`, `GeneratorPreview(Website website)`, `GeneratorError(String stage, String error)`
- **Responsibilities:** Orchestrate AI pipeline, stream generation progress, cache results

#### `DeploymentBloc`
- **Events:** `Deploy(DeploymentTarget target, Website website)`, `CheckStatus(String deploymentId)`, `Redeploy(String deploymentId)`, `ConfigureCredentials(PlatformCredentials creds)`
- **States:** `DeploymentIdle`, `DeploymentConfiguring`, `DeploymentInProgress(double progress)`, `DeploymentSuccess(DeploymentResult result)`, `DeploymentFailed(String error)`
- **Responsibilities:** Platform API orchestration, polling deployment status, credential management

#### `GitHubPublisherBloc`
- **Events:** `PublishRepository(String repoName, Website website)`, `UpdateRepository(String repoName, Website website)`, `CheckRepositoryExists(String repoName)`
- **States:** `PublisherIdle`, `PublisherCreating`, `PublisherUploading(double progress)`, `PublisherSuccess(GitHubResult result)`, `PublisherError(String error)`
- **Responsibilities:** GitHub REST API v3 integration, base64 content uploads, tree/blob creation

#### `SupportChatBloc`
- **Events:** `SendMessage(String message)`, `LoadHistory()`, `ClearHistory()`
- **States:** `ChatLoading`, `ChatLoaded(List<Message> messages)`, `ChatStreaming(String partialResponse)`, `ChatError`
- **Responsibilities:** Multi-model chat routing, context-aware resume support

### 3.2 BLoC Communication Pattern
```dart
// Cross-BLoC communication via Domain Events (Event Bus)
class WebsiteGeneratedDomainEvent {
  final Website website;
  WebsiteGeneratedDomainEvent(this.website);
}

// DeploymentBloc listens to WebsiteGeneratedDomainEvent to offer quick-deploy
```

---

## 4. DATA MODELS (JSON-Serializable)

### 4.1 Core Entities

```dart
// resume.dart
class Resume extends Equatable {
  final String id;
  final PersonalInfo personalInfo;
  final List<Experience> experiences;
  final List<Education> education;
  final List<Skill> skills;
  final List<Project> projects;
  final List<Certification> certifications;
  final String? rawText; // For AI context
  final DateTime lastUpdated;

  // Equatable + JSON serialization required
}

class PersonalInfo {
  final String fullName;
  final String? title;
  final String email;
  final String? phone;
  final String? location;
  final String? linkedIn;
  final String? github;
  final String? portfolio;
  final String? bio; // AI-enhanced summary
}

class Experience {
  final String company;
  final String role;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String description; // Bullet points
  final List<String> achievements; // AI-extracted
  final List<String> technologies;
}
```

### 4.2 Website Entity

```dart
class Website extends Equatable {
  final String id;
  final String name; // e.g., "john-doe-portfolio"
  final Resume sourceResume;
  final TemplateStyle template;
  final WebsiteAssets assets;
  final String htmlContent;
  final String? cssContent;
  final String? jsContent;
  final Map<String, String> additionalFiles; // filename -> content
  final GenerationMetadata metadata;
  final DateTime generatedAt;
}

class WebsiteAssets {
  final String? profileImageBase64;
  final List<ProjectAsset> projectImages;
  final ColorScheme generatedColorScheme; // AI-generated from resume tone
}

class GenerationMetadata {
  final String modelUsed; // "claude-3.5-sonnet" | "gpt-4o"
  final int tokensUsed;
  final Duration generationTime;
  final String genKitFlowId;
  final List<String> generationStages; // For progress tracking
}
```

### 4.3 Deployment Entity

```dart
class Deployment extends Equatable {
  final String id;
  final String websiteId;
  final DeploymentTarget target;
  final DeploymentStatus status;
  final String? liveUrl;
  final String? previewUrl;
  final DateTime createdAt;
  final DateTime? deployedAt;
  final Map<String, dynamic> platformMetadata; // Vercel/Netlify/CF specific
}

enum DeploymentTarget { vercel, cloudflarePages, netlify, githubPages }

enum DeploymentStatus { 
  pending, 
  building, 
  ready, 
  error, 
  canceled 
}

class PlatformCredentials {
  final String platform; // "vercel" | "cloudflare" | "netlify" | "github"
  final String token;
  final String? teamId; // For Vercel teams
  final String? accountId; // For Cloudflare
}
```

---

## 5. AI INTEGRATION ARCHITECTURE

### 5.1 Firebase GenKit (Primary Orchestration)

**Setup:**
- Deploy GenKit flows to Firebase Cloud Functions (Node.js)
- Flutter app calls GenKit via HTTP/Callable functions
- GenKit acts as the "AI router" — decides which model to use for which task

**GenKit Flows:**

#### Flow 1: `parseResumeFlow`
```typescript
// GenKit Flow Definition
export const parseResumeFlow = defineFlow({
  name: "parseResume",
  inputSchema: z.object({
    rawText: z.string(),
    fileType: z.enum(["pdf", "docx", "txt", "json"])
  }),
  outputSchema: ResumeSchema,
}, async (input) => {
  // Use GPT-4o for structured extraction
  const result = await ai.generate({
    model: gpt4o,
    prompt: `Extract structured resume data from the following text. ...`,
    output: { schema: ResumeSchema }
  });
  return result.output;
});
```

#### Flow 2: `generateWebsiteFlow` (CRITICAL — Claude 3.5 Sonnet)
```typescript
export const generateWebsiteFlow = defineFlow({
  name: "generateWebsite",
  inputSchema: z.object({
    resume: ResumeSchema,
    template: z.enum(["modern", "minimal", "creative", "professional", "developer"]),
    colorPreference: z.string().optional(),
    language: z.string().default("en")
  }),
  outputSchema: z.object({
    html: z.string(),
    css: z.string(),
    js: z.string().optional(),
    assets: z.array(z.object({ filename: z.string(), base64: z.string() })),
    colorScheme: z.object({ primary: z.string(), secondary: z.string(), accent: z.string() }),
    metadata: z.object({ model: z.string(), tokens: z.number() })
  }),
}, async (input) => {
  // Stage 1: Claude 3.5 Sonnet generates the design system + HTML structure
  const designSystem = await ai.generate({
    model: claude35Sonnet,
    prompt: `You are an expert frontend developer. Create a complete, responsive personal website 
    from this resume data. Use Tailwind CSS via CDN. The HTML must be single-file, self-contained,
    with embedded CSS and JS. Include: Hero section, About, Experience timeline, Skills visualization,
    Projects grid, Education, Contact form. Resume: ${JSON.stringify(input.resume)}`,
    config: { temperature: 0.7, maxOutputTokens: 8192 }
  });

  // Stage 2: GPT-4o mini reviews and optimizes for mobile
  const optimized = await ai.generate({
    model: gpt4oMini,
    prompt: `Review this HTML for mobile responsiveness and accessibility. Fix any issues.
    HTML: ${designSystem.text}`,
    config: { temperature: 0.3 }
  });

  return {
    html: optimized.text,
    css: "", // embedded in HTML
    js: "",  // embedded in HTML
    metadata: { model: "claude-3.5-sonnet+gpt-4o-mini", tokens: designSystem.usage.totalTokens }
  };
});
```

#### Flow 3: `enhanceResumeFlow`
```typescript
// Uses Claude for writing enhancement, GPT for keyword optimization
export const enhanceResumeFlow = defineFlow({...});
```

#### Flow 4: `supportChatFlow`
```typescript
// Multi-turn chat with resume context injection
export const supportChatFlow = defineFlow({
  name: "supportChat",
  inputSchema: z.object({
    message: z.string(),
    history: z.array(z.object({ role: z.enum(["user","model"]), text: z.string() })),
    resumeContext: ResumeSchema.optional()
  }),
}, async (input) => {
  // Route to GPT-4o for general questions, Claude for writing/editing tasks
  const intent = await classifyIntent(input.message);
  const model = intent === "writing" ? claude35Sonnet : gpt4o;

  return ai.generate({
    model,
    prompt: buildSupportPrompt(input),
    config: { temperature: 0.8 }
  });
});
```

### 5.2 Flutter → GenKit Client

```dart
class GenKitClient {
  final Dio _dio;
  final String _baseUrl;

  GenKitClient(this._baseUrl, {required String apiKey})
      : _dio = Dio(BaseOptions(
          headers: {"Authorization": "Bearer $apiKey"},
          connectTimeout: Duration(minutes: 2),
          receiveTimeout: Duration(minutes: 3),
        ));

  Future<Website> generateWebsite(GenerateWebsiteRequest request) async {
    final response = await _dio.post(
      "$_baseUrl/generateWebsite",
      data: request.toJson(),
      onReceiveProgress: (received, total) {
        // Stream progress to BLoC
      },
    );
    return WebsiteModel.fromJson(response.data).toEntity();
  }

  Stream<GenerationProgress> generateWebsiteStream(GenerateWebsiteRequest request) async* {
    // For SSE (Server-Sent Events) progress streaming
    final response = await _dio.get(
      "$_baseUrl/generateWebsiteStream",
      queryParameters: request.toJson(),
      options: Options(responseType: ResponseType.stream),
    );

    await for final chunk in response.data.stream {
      yield GenerationProgress.fromJson(jsonDecode(chunk));
    }
  }
}
```

---

## 6. DEPLOYMENT INTEGRATIONS (No Git CLI)

### 6.1 Vercel API Integration

**API:** REST API v7 (https://api.vercel.com)
**Authentication:** Bearer Token (User's Vercel Token)
**Flow:**
1. Create deployment via `/v13/deployments`
2. Upload files as base64-encoded blobs
3. Poll deployment status
4. Return production URL

```dart
class VercelApiClient {
  static const String _baseUrl = "https://api.vercel.com";
  final Dio _dio;

  VercelApiClient({required String token})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          headers: {"Authorization": "Bearer $token"},
        ));

  Future<DeploymentResult> deployWebsite(Website website, {String? teamId}) async {
    // Step 1: Prepare files
    final files = _prepareFiles(website);

    // Step 2: Create deployment
    final response = await _dio.post("/v13/deployments", data: {
      "name": website.name,
      "files": files.map((f) => {
        "file": f.path,
        "data": f.base64Content,
        "encoding": "base64"
      }).toList(),
      "target": "production",
      if (teamId != null) "teamId": teamId,
      "projectSettings": {
        "framework": null, // Static HTML
        "buildCommand": null,
        "outputDirectory": "."
      }
    });

    return DeploymentResult.fromJson(response.data);
  }

  Future<DeploymentStatus> checkStatus(String deploymentId, {String? teamId}) async {
    final response = await _dio.get("/v13/deployments/$deploymentId", queryParameters: {
      if (teamId != null) "teamId": teamId,
    });
    return DeploymentStatus.fromJson(response.data);
  }
}
```

### 6.2 Cloudflare Pages API

**API:** Cloudflare REST API v4 (https://api.cloudflare.com/client/v4)
**Authentication:** API Token (Account > Pages:Edit, Account:Read)
**Flow:**
1. Create project via `/accounts/{account_id}/pages/projects`
2. Upload via Direct Upload API (generate upload URL, POST files)
3. Poll deployment

```dart
class CloudflareApiClient {
  static const String _baseUrl = "https://api.cloudflare.com/client/v4";
  final Dio _dio;
  final String _accountId;

  CloudflareApiClient({required String token, required String accountId})
      : _accountId = accountId,
        _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json"
          },
        ));

  Future<DeploymentResult> deployWebsite(Website website) async {
    final projectName = website.name;

    // Step 1: Ensure project exists
    try {
      await _dio.get("/accounts/$_accountId/pages/projects/$projectName");
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _dio.post("/accounts/$_accountId/pages/projects", data: {
          "name": projectName,
          "production_branch": "main"
        });
      }
    }

    // Step 2: Get upload URL
    final uploadUrlResponse = await _dio.post(
      "/accounts/$_accountId/pages/projects/$projectName/deployments"
    );
    final uploadUrl = uploadUrlResponse.data["result"]["upload_url"];

    // Step 3: Upload files (multipart/form-data)
    final formData = FormData();
    for (final file in _prepareFiles(website)) {
      formData.files.add(MapEntry(
        file.path,
        MultipartFile.fromBytes(base64Decode(file.base64Content), filename: file.path),
      ));
    }

    await Dio().post(uploadUrl, data: formData);

    return DeploymentResult(
      url: "https://$projectName.pages.dev",
      status: DeploymentStatus.ready,
    );
  }
}
```

### 6.3 Netlify API Integration

**API:** Netlify REST API (https://api.netlify.com/api/v1)
**Authentication:** Personal Access Token
**Flow:**
1. Create site (if not exists) via `POST /sites`
2. Deploy via `POST /sites/{site_id}/deploys` with file digest
3. Upload required files via `PUT /deploys/{deploy_id}/files/{path}`

```dart
class NetlifyApiClient {
  static const String _baseUrl = "https://api.netlify.com/api/v1";
  final Dio _dio;

  NetlifyApiClient({required String token})
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          headers: {"Authorization": "Bearer $token"},
        ));

  Future<DeploymentResult> deployWebsite(Website website) async {
    // Step 1: Create or get site
    final siteName = website.name;
    Site site;
    try {
      final sites = await _dio.get("/sites", queryParameters: {"name": siteName});
      site = Site.fromJson(sites.data[0]);
    } catch (_) {
      final newSite = await _dio.post("/sites", data: {"name": siteName});
      site = Site.fromJson(newSite.data);
    }

    // Step 2: Create deploy with file digests (SHA1)
    final files = _prepareFiles(website);
    final fileDigests = { for (var f in files) f.path: sha1(f.content) };

    final deployResponse = await _dio.post(
      "/sites/${site.id}/deploys",
      data: {"files": fileDigests, "async": true},
    );
    final deployId = deployResponse.data["id"];

    // Step 3: Upload files that don't exist (required = true in response)
    final requiredFiles = deployResponse.data["required"] as List;
    for (final file in files) {
      if (requiredFiles.contains(file.path)) {
        await _dio.put(
          "/deploys/$deployId/files/${Uri.encodeComponent(file.path)}",
          data: file.content,
          options: Options(headers: {"Content-Type": "application/octet-stream"}),
        );
      }
    }

    return DeploymentResult(
      url: site.sslUrl ?? site.url,
      deployId: deployId,
      status: DeploymentStatus.building,
    );
  }
}
```

### 6.4 GitHub Publisher (Zero Git)

**API:** GitHub REST API v3 + GraphQL (optional)
**Authentication:** Personal Access Token (repo scope) or GitHub App
**Flow:** Create repo → Create tree with blobs → Create commit → Update ref

```dart
class GitHubApiPublisher {
  static const String _baseUrl = "https://api.github.com";
  final Dio _dio;
  final String _username;

  GitHubApiPublisher({required String token, required String username})
      : _username = username,
        _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          headers: {
            "Authorization": "token $token",
            "Accept": "application/vnd.github.v3+json"
          },
        ));

  Future<GitHubResult> publishRepository(Website website, {bool isPrivate = false}) async {
    final repoName = website.name;

    // Step 1: Create repository
    try {
      await _dio.post("/user/repos", data: {
        "name": repoName,
        "description": "Personal portfolio website generated by Resumate",
        "private": isPrivate,
        "auto_init": false,
        "license_template": "mit"
      });
    } on DioException catch (e) {
      if (e.response?.statusCode != 422) rethrow; // 422 = already exists
    }

    // Step 2: Get latest commit SHA (for base tree)
    final refResponse = await _dio.get("/repos/$_username/$repoName/git/ref/heads/main");
    final latestCommitSha = refResponse.data["object"]["sha"];

    // Step 3: Create blobs for each file
    final files = _prepareFiles(website);
    final treeItems = <Map<String, dynamic>>[];

    for (final file in files) {
      final blobResponse = await _dio.post(
        "/repos/$_username/$repoName/git/blobs",
        data: {
          "content": file.base64Content,
          "encoding": "base64"
        },
      );
      treeItems.add({
        "path": file.path,
        "mode": "100644",
        "type": "blob",
        "sha": blobResponse.data["sha"]
      });
    }

    // Step 4: Create tree
    final treeResponse = await _dio.post(
      "/repos/$_username/$repoName/git/trees",
      data: {
        "base_tree": latestCommitSha,
        "tree": treeItems
      },
    );

    // Step 5: Create commit
    final commitResponse = await _dio.post(
      "/repos/$_username/$repoName/git/commits",
      data: {
        "message": "Generated portfolio website from Resumate",
        "tree": treeResponse.data["sha"],
        "parents": [latestCommitSha]
      },
    );

    // Step 6: Update reference
    await _dio.patch(
      "/repos/$_username/$repoName/git/refs/heads/main",
      data: {"sha": commitResponse.data["sha"]},
    );

    // Step 7: Enable GitHub Pages if needed
    await _dio.post(
      "/repos/$_username/$repoName/pages",
      data: {"source": {"branch": "main", "path": "/"}},
    );

    return GitHubResult(
      repoUrl: "https://github.com/$_username/$repoName",
      pagesUrl: "https://$_username.github.io/$repoName",
      commitSha: commitResponse.data["sha"],
    );
  }
}
```

---

## 7. FEATURE MODULES

### 7.1 Resume Input Module
**Features:**
- PDF/Word parsing (use `syncfusion_flutter_pdf` + `docx` package)
- Manual form entry with AI autocomplete
- LinkedIn profile import (OAuth2 + API)
- AI extraction confidence scoring (show user which fields need review)

**UI Flow:**
```
Upload Screen → Parsing Progress (AI) → Review Screen (highlight low-confidence fields) → Edit Screen → Save
```

### 7.2 Website Generator Module
**Features:**
- Template selection: Modern, Minimal, Creative, Professional, Developer
- AI color scheme generation from resume "tone"
- Real-time preview (WebView or custom renderer)
- Section-level regeneration ("Make experience section more technical")
- A/B comparison (compare two generated versions)

**UI Flow:**
```
Template Selection → AI Generation (streaming progress) → Preview → Edit Prompts → Finalize
```

### 7.3 Deployment Dashboard
**Features:**
- Platform credential management (secure storage via `flutter_secure_storage`)
- One-tap deploy to any configured platform
- Deployment history and status monitoring
- URL management (custom domains, redirects)
- Analytics integration (Plausible/GA4 script injection)

### 7.4 Support AI Chat Module
**Features:**
- Context-aware: AI knows user's resume
- Capabilities: Resume review, cover letter generation, interview prep, salary negotiation tips
- Model routing: Writing tasks → Claude, Quick facts → GPT-4o
- Export chat history to PDF

---

## 8. SECURITY & STORAGE

### 8.1 Local Storage (Hive)
```dart
// Boxes:
- resumeBox: Resume entities
- websiteBox: Generated websites (cache)
- deploymentBox: Deployment history
- credentialsBox: Encrypted platform tokens (AES-256 via flutter_secure_storage keys)
- settingsBox: User preferences
```

### 8.2 Secure Credential Management
```dart
class SecureCredentialStorage {
  final FlutterSecureStorage _secureStorage;

  Future<void> storeCredentials(String platform, PlatformCredentials creds) async {
    final key = await _secureStorage.read(key: "master_key") ?? await _generateMasterKey();
    final encrypted = _encrypt(jsonEncode(creds.toJson()), key);
    await _secureStorage.write(key: "creds_$platform", value: encrypted);
  }

  Future<PlatformCredentials?> getCredentials(String platform) async {
    final encrypted = await _secureStorage.read(key: "creds_$platform");
    if (encrypted == null) return null;
    final key = await _secureStorage.read(key: "master_key");
    final decrypted = _decrypt(encrypted, key!);
    return PlatformCredentials.fromJson(jsonDecode(decrypted));
  }
}
```

---

## 9. UI/UX SPECIFICATIONS

### 9.1 Design System
- **Framework:** Material 3 with custom theme
- **Colors:** Dynamic color from AI-generated website scheme
- **Typography:** Inter / Roboto
- **Animations:** `flutter_animate` for generation stages
- **Icons:** Phosphor Icons

### 9.2 Key Screens

#### Home Dashboard
```
┌─────────────────────────────┐
│  Resumate        [Settings] │
├─────────────────────────────┤
│  [Resume Card]              │
│  Name: John Doe             │
│  Status: Complete ✓         │
│  [Edit] [Preview]           │
├─────────────────────────────┤
│  [Website Card]             │
│  Last Generated: 2h ago     │
│  [View] [Regenerate] [Deploy]│
├─────────────────────────────┤
│  Quick Actions              │
│ [🚀 Deploy] [💬 Support]    │
└─────────────────────────────┘
```

#### Generation Screen (Streaming)
```
┌─────────────────────────────┐
│  Generating Website...      │
│                             │
│  ⚡ Analyzing resume... ✓   │
│  🎨 Creating design... ✓   │
│  💻 Building HTML...  →     │
│  📱 Optimizing mobile...    │
│  🔍 Final review...         │
│                             │
│  [Progress Bar]             │
│  [Cancel]                   │
└─────────────────────────────┘
```

#### Deployment Screen
```
┌─────────────────────────────┐
│  Deploy to:                 │
│  [Vercel] [CF] [Netlify]    │
│  [GitHub Pages]             │
│                             │
│  Status: Building...        │
│  [Live Preview]             │
│  [Open URL] [Redeploy]      │
└─────────────────────────────┘
```

---

## 10. API SCHEMAS (For GenKit Backend)

### 10.1 GenerateWebsite Request
```json
{
  "resume": {
    "personalInfo": { "fullName": "...", "email": "..." },
    "experiences": [{ "company": "...", "role": "..." }],
    "skills": [{ "name": "Flutter", "level": "expert" }]
  },
  "template": "modern",
  "options": {
    "language": "en",
    "includeContactForm": true,
    "includeBlog": false,
    "darkMode": true,
    "animations": "subtle"
  }
}
```

### 10.2 GenerateWebsite Response
```json
{
  "html": "<!DOCTYPE html>...",
  "css": "/* optional separate stylesheet */",
  "js": "// optional interactions",
  "assets": [
    { "filename": "profile.jpg", "base64": "/9j/4AAQ..." }
  ],
  "colorScheme": {
    "primary": "#3B82F6",
    "secondary": "#1E293B",
    "accent": "#F59E0B"
  },
  "metadata": {
    "model": "claude-3.5-sonnet",
    "tokens": 4521,
    "duration": "12.4s"
  }
}
```

---

## 11. ERROR HANDLING & RETRY LOGIC

### 11.1 AI Generation Failures
```dart
class GenerationRetryPolicy {
  static const int maxRetries = 3;
  static const List<int> retryableStatusCodes = [429, 500, 502, 503];

  Future<T> execute<T>(Future<T> Function() operation, {String? fallbackModel}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } on AIException catch (e) {
        if (e.statusCode == 429) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
          continue;
        }
        if (i == maxRetries - 1 && fallbackModel != null) {
          return await _switchModelAndRetry(operation, fallbackModel);
        }
        rethrow;
      }
    }
    throw GenerationException("Max retries exceeded");
  }
}
```

### 11.2 Deployment Failures
- Network timeout: Auto-retry with exponential backoff
- Invalid credentials: Prompt user immediately
- Platform limit reached: Suggest alternative platform
- Build failure: Show logs, offer AI fix suggestion

---

## 12. TESTING STRATEGY

### 12.1 Unit Tests
- BLoC tests using `bloc_test`
- Use case tests with mocked repositories
- API client tests with `dio` interceptors + `mocktail`

### 12.2 Integration Tests
- Full generation flow: Resume → Website → HTML validation
- Deployment flow: Mock platform APIs
- End-to-end: Upload PDF → Deploy to Vercel (staging token)

### 12.3 AI Output Validation
```dart
test("Generated HTML contains all resume sections", () {
  final html = generatedWebsite.html;
  expect(html, contains(resume.personalInfo.fullName));
  expect(html, contains(resume.experiences.first.company));
  expect(html, contains('<!DOCTYPE html>'));
  expect(html, contains('</html>'));
});
```

---

## 13. MONETIZATION & LIMITS

### 13.1 Freemium Tiers
- **Free:** 3 generations/month, 1 deployment, basic templates
- **Pro:** Unlimited generations, all platforms, custom domains, priority AI (Claude)
- **Enterprise:** Team management, white-label, API access

### 13.2 Rate Limiting
- Client-side tracking via `rate_limiter` package
- Server-side Firebase Functions enforcement
- Graceful degradation: Queue requests, notify when ready

---

## 14. PROMPT ENGINEERING GUIDELINES (For AI Models)

### 14.1 Website Generation System Prompt (Claude)
```
You are ResumateAI, an expert frontend developer specializing in portfolio websites.

RULES:
1. Generate complete, self-contained single-file HTML with embedded Tailwind CSS
2. Use Tailwind CDN: https://cdn.tailwindcss.com
3. Include responsive meta tags and viewport settings
4. All sections must have semantic HTML5 tags
5. Include smooth scroll behavior and subtle animations
6. Contact form must be functional (Formspree or similar)
7. Dark mode support via Tailwind 'dark:' classes
8. Optimize for Core Web Vitals (minimal JS, compressed assets)
9. Accessibility: ARIA labels, alt text, keyboard navigation
10. The design should reflect the candidate's industry (tech = modern/minimal, creative = bold/colors)

OUTPUT FORMAT:
Return ONLY the complete HTML string. No markdown code blocks. No explanations.
```

### 14.2 Resume Parsing System Prompt (GPT-4o)
```
Extract structured resume information from the provided text.

INSTRUCTIONS:
- Infer missing dates if possible (e.g., "2020-2022" pattern)
- Normalize job titles to standard industry terms
- Extract technologies as separate skill tags
- Calculate total years of experience
- Identify gaps in employment (>3 months)
- Confidence score 0-1 for each extracted field

OUTPUT: Strict JSON matching the ResumeSchema.
```

---

## 15. DEPENDENCIES (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  equatable: ^2.0.5

  # Networking
  dio: ^5.4.0
  retrofit: ^4.0.3

  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.0.0

  # Parsing
  syncfusion_flutter_pdf: ^24.1.41
  docx: ^0.0.1

  # UI
  flutter_animate: ^4.3.0
  phosphor_flutter: ^2.0.1
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9

  # Utilities
  crypto: ^3.0.3
  path_provider: ^2.1.1
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  image_picker: ^1.0.7

  # Firebase (GenKit)
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_functions: ^4.5.8

dev_dependencies:
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
  json_serializable: ^6.7.1
  retrofit_generator: ^8.0.6
  bloc_test: ^9.1.5
  mocktail: ^1.0.1
  flutter_test:
    sdk: flutter
```

---

## 16. IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Week 1-2)
- [ ] Project setup with Clean Architecture + BLoC
- [ ] Local storage (Hive) + secure credentials
- [ ] Resume input forms + basic PDF parsing
- [ ] GenKit backend setup + `parseResumeFlow`

### Phase 2: AI Generation (Week 3-4)
- [ ] `generateWebsiteFlow` with Claude 3.5
- [ ] Template system + preview WebView
- [ ] Streaming progress UI
- [ ] HTML validation + mobile optimization

### Phase 3: Deployment (Week 5-6)
- [ ] Vercel API integration
- [ ] Cloudflare Pages integration
- [ ] Netlify API integration
- [ ] GitHub API publisher (zero-Git)
- [ ] Deployment dashboard + status polling

### Phase 4: Support & Polish (Week 7-8)
- [ ] Support chat with context injection
- [ ] Settings + credential management
- [ ] Analytics + error tracking (Sentry)
- [ ] App Store / Play Store preparation

---

## 17. CLAUDE CODE PROMPT (Copy-Paste Ready)

When using Claude Code, paste this as your initial prompt:

```
I am building Resumate, a Flutter app that uses AI to convert resumes into deployed websites.

STACK:
- Flutter 3.16+ with Material 3
- BLoC pattern (flutter_bloc) for ALL state management
- Clean Architecture (Domain/Data/Presentation layers)
- Firebase GenKit (Node.js backend) for AI orchestration
- Claude 3.5 Sonnet for website generation
- GPT-4o for resume parsing and support chat

FEATURES TO BUILD:
1. Resume input: PDF/Word parsing, manual forms, LinkedIn import
2. AI website generation: 5 templates, streaming progress, real-time preview
3. One-tap deployment: Vercel, Cloudflare Pages, Netlify APIs (no Git CLI)
4. GitHub publishing: Create repos and upload files via GitHub REST API v3 (no Git)
5. Support AI chat: Context-aware resume assistance with model routing
6. Secure credential storage for all platforms

CURRENT TASK: [Specify module here, e.g., "Build the WebsiteGeneratorBloc with streaming states"]

CONSTRAINTS:
- Use Equatable for all states/events
- All API clients must use Dio with proper interceptors
- Secure storage via flutter_secure_storage + AES encryption
- Follow the folder structure: lib/features/{feature}/{domain,data,presentation}/
- Write unit tests for all BLoCs using bloc_test
- Use Retrofit for type-safe API clients where applicable
```

---

**Document Version:** 1.0.0  
**Generated for:** Resumate Flutter Application  
**AI Stack:** GenKit + Claude 3.5 Sonnet + GPT-4o  
**State Management:** BLoC (flutter_bloc)  
**Architecture:** Clean Architecture
