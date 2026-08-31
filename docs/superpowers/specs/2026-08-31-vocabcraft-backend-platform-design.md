# VocabCraft Backend Platform & Codebase Improvement — Technical Design Specification

**Date:** 2026-08-31
**Status:** Draft — Pending Review
**Author:** OpenCode (Muse Spark) + hoojinguyen
**Approach:** FastAPI Modular Monolith (self-host 100%, offline-first + delta sync)
**Scope:** Backend platform (Content CMS + User Sync), iOS health/perf/bugs, feature backlog for solo part-time

---

## 1. Executive Summary

VocabCraft đã có core features hoàn chỉnh (Homepage/LearningPath, Vocabulary TopicDecks/PersonalVault/SmartReview/QuickReflexDrill, ReflexBlitz 4 modes, Settings, Widget) với ~25.6k LOC, 160 Swift files, `CraftUIKit` + `SpeechKit`. Mọi data hiện là sample hardcode (`VocabularySampleDataset.swift:293` 50 từ, 4 decks 8 stages) và `DatasetEngine.swift:5` đọc `english_dataset.db` nhưng chưa có DB bundle, `AppContainer.swift:78` luôn fallback `SampleVocabularyDataSource`.

Mục tiêu: xây nền tảng backend self-host để phục vụ app, **vừa Content CMS động vừa User Cloud Sync**, giữ **offline-first** (bundle + SwiftData `user_progress.sqlite` trong App Group `group.com.hoojinguyen.vocabcraft`), solo dev part-time làm incremental. Spec này định nghĩa kiến trúc, data contract, sync strategy và backlog 31 tickets (94 points) có thứ tự.

---

## 2. Goals & Constraints

**Goals:**
- Thay sample tĩnh bằng content động có versioning, import pipeline, scale 50→2500 từ.
- Đồng bộ `UserWordProgress`, `UserStageProgress`, `QuickReflexAttemptRecord` cross-device, backup, khôi phục.
- Giữ offline-first: mọi write local trước, queue sync khi online; đọc ưu tiên cache, fallback bundle.
- Fix bugs/blockers, refactor `AppContainer`, cải thiện build perf (24.8s clean → <15s), chuẩn `swiftlint` 0 warnings, `swift test` pass.
- Backlog sliceable cho solo 10-15h/tuần.

**Constraints:**
- Self-host 100% (không BaaS), 1 VPS 2vCPU/4GB Docker Compose.
- Stack backend: Python FastAPI (ưu tiên velocity, khớp pipeline NLP) — contract trung lập để sau rewrite Go không đổi iOS.
- Solo part-time → mỗi ticket ≤8pt, có dependency rõ, làm theo wave 6 tuần.
- Giữ bilingual parity `Localizable.xcstrings`, CraftUIKit-first, zero hardcoded strings.

**Non-goals (v1):**
- Realtime collaboration, social leaderboard server, AI LLM training pipeline (chỉ generate example/collocation cache).

---

## 3. System Architecture

### 3.1 Repo Layout

```
/vocab-craft-app
  VocabCraftApp/ (iOS App, SwiftData, SwiftUI)
  Packages/CraftUIKit, SpeechKit
  docs/superpowers/specs/, plans/
  VocabCraft.xcworkspace, VocabCraftApp.xcodeproj
/backend                     # mới
  app/
    core/ (config.py, db.py, security.py, errors.py, logging.py)
    modules/
      auth/ (router.py, service.py, models.py, schemas.py)
      content/ (router.py, service.py, models.py, schemas.py, import.py)
      progress/ (router.py, service.py, models.py, schemas.py)
      sync/ (router.py, service.py)
    api/v1/ (deps.py, router.py)
  alembic/ (env.py, versions/)
  tests/ (test_auth.py, test_content.py, test_sync.py)
  Dockerfile (python:3.12-slim)
  docker-compose.yml (app, postgres:16, caddy/nginx, pgadmin optional)
  .env.example
```

### 3.2 Runtime Self-Host

- VPS chạy `docker compose up --build` — `app:8000` (FastAPI), `postgres:16` volume `pgdata`, `caddy:80/443` terminate TLS Let's Encrypt, proxy `/api` → `app:8000`, `/health` → `app:8000/health`.
- Backup: cron `pg_dump -Fc > /backups/pg-$(date +%F).dump` daily, retain 7d, copy offsite rclone.
- Không Redis v1 (in-memory rate limit 100 req/60s/IP); thêm khi cần.

### 3.3 iOS New Layers

```
VocabCraftApp/Core/Network/
  APIClient.swift (URLSession async/await, Endpoint enum, RequestBuilder, AuthInterceptor, RetryPolicy exponential 1s/2s/4s)
  AuthStore.swift (Keychain kSecClassGenericPassword, accessToken/refreshToken)
  DTOs/ (generated from OpenAPI Pydantic, Codable + ISO8601)
VocabCraftApp/Core/Sync/
  SyncEngine.swift (push/pull, NWPathMonitor, BGTaskScheduler)
  SyncOperation.swift (SwiftData @Model, persistent queue)
  SyncMetadataStore.swift (lastSyncToken in UserDefaults + SwiftData)
  ConflictResolver.swift (last-write-wins version+updatedAt)
VocabCraftApp/Core/Database/
  DatasetEngine.swift: refactor @MainActor → actor + sqlite3 off-main queue + ContentCache.sqlite
```

**Offline-first invariant:** Local SwiftData là source of truth; backend là replica. Mọi `recordReview`/`saveStageProgress` ghi local trước, enqueue, không block UI chờ mạng.

---

## 4. Data Models & API Contract

### 4.1 Backend Postgres Schema (tái sử dụng `english_dataset.db` + sync metadata)

```sql
-- Content (public, versioned, soft-delete)
topic_decks(id TEXT PK, title TEXT NOT NULL, icon_name TEXT, badge_color_hex TEXT, cefr_level TEXT, sort_order INT NOT NULL, updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), version INT NOT NULL DEFAULT 1, deleted_at TIMESTAMPTZ)
topic_nodes(id TEXT PK, deck_id TEXT NOT NULL REFERENCES topic_decks(id), title TEXT NOT NULL, icon_name TEXT, sort_order INT NOT NULL, updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), version INT NOT NULL DEFAULT 1, deleted_at TIMESTAMPTZ)
words(id BIGINT PK, lemma TEXT NOT NULL, pos TEXT, ipa_us TEXT, cefr_level TEXT, updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), version INT NOT NULL DEFAULT 1, deleted_at TIMESTAMPTZ)
definitions(id BIGINT PK, word_id BIGINT NOT NULL REFERENCES words(id), definition_en TEXT, definition_vi TEXT, example TEXT, updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), version INT NOT NULL DEFAULT 1, deleted_at TIMESTAMPTZ)
node_words(node_id TEXT NOT NULL REFERENCES topic_nodes(id), word_id BIGINT NOT NULL REFERENCES words(id), PRIMARY KEY(node_id, word_id))
sentences(id BIGINT PK, text_en TEXT NOT NULL, text_vi TEXT, cefr_level TEXT)
reflex_drills(id BIGINT PK, sentence_id BIGINT REFERENCES sentences(id), drill_type TEXT NOT NULL, prompt_text TEXT NOT NULL, correct_answer TEXT NOT NULL, distractors_json JSONB NOT NULL DEFAULT '[]', target_time_ms INT NOT NULL)
content_manifest(version INT PK, checksum TEXT NOT NULL, total_words INT NOT NULL, total_decks INT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now())

-- User (per-user, auth required)
users(id UUID PK DEFAULT gen_random_uuid(), email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now())
user_word_progress(user_id UUID NOT NULL REFERENCES users(id), word_id BIGINT NOT NULL, mastery_level INT NOT NULL DEFAULT 0, ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5, interval_days INT NOT NULL DEFAULT 1, next_review_date TIMESTAMPTZ NOT NULL DEFAULT now(), last_review_date TIMESTAMPTZ NOT NULL DEFAULT now(), is_bookmarked BOOLEAN NOT NULL DEFAULT false, mistake_count INT NOT NULL DEFAULT 0, consecutive_streak INT NOT NULL DEFAULT 0, practiced_modes TEXT NOT NULL DEFAULT '', is_mastered BOOLEAN NOT NULL DEFAULT false, source_deck_id TEXT, source_node_id TEXT, version INT NOT NULL DEFAULT 1, updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), deleted_at TIMESTAMPTZ, PRIMARY KEY(user_id, word_id))
user_stage_progress(user_id UUID NOT NULL REFERENCES users(id), stage_id TEXT NOT NULL, deck_id TEXT NOT NULL, is_completed BOOLEAN NOT NULL DEFAULT false, score INT NOT NULL DEFAULT 0, progress_fraction DOUBLE PRECISION NOT NULL DEFAULT 0, completed_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(), version INT NOT NULL DEFAULT 1, deleted_at TIMESTAMPTZ, PRIMARY KEY(user_id, stage_id))
quick_reflex_attempts(id UUID PK DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id), word_id BIGINT NOT NULL, recall_time_ms INT NOT NULL, collocation_time_ms INT NOT NULL DEFAULT 0, produce_time_ms INT NOT NULL, recall_ok BOOLEAN NOT NULL, collocation_ok BOOLEAN NOT NULL, produce_ok BOOLEAN NOT NULL, shadow_score DOUBLE PRECISION, hint_level INT NOT NULL, input_mode TEXT NOT NULL, retry_count INT NOT NULL, confidence TEXT NOT NULL, timestamp TIMESTAMPTZ NOT NULL DEFAULT now())
```

Mapping iOS `SwiftDataModels.swift` (`UserWordProgress`, `UserStageProgress`, `QuickReflexAttemptRecord`, `ReflexSessionLog`, `WidgetCurrentState`) → thêm `version: Int`, `updatedAt: Date`, `deletedAt: Date?` trong `SchemaV3`. `WordDTO`/`TopicDeckDTO` (`VocabularySampleDataset.swift`) thêm `version`, `updatedAt`.

### 4.2 API Contract `/api/v1` (OpenAPI 3.1, Pydantic v2 → Swift Codable ISO8601)

**Auth (public):**
- `POST /auth/register {email, password}` → `201 {access_token, refresh_token, user: {id, email}}` | `409 email exists`
- `POST /auth/login {email, password}` → `200 {access_token, refresh_token}` | `401`
- `POST /auth/refresh {refresh_token}` → `200 {access_token, refresh_token}` | `401`
- `POST /auth/logout` (Bearer) → `204`

**Content (public, cached ETag, `Cache-Control: public, max-age=300`):**
- `GET /content/manifest` → `{version, checksum, total_words, total_decks, created_at}`
- `GET /content/decks` → `[TopicDeckDTO]`
- `GET /content/decks/{id}/nodes` → `[TopicNodeDTO]`
- `GET /content/nodes/{id}/words` → `[WordDTO]`
- `GET /content/words?limit=50&cefr=B2&q=algorithm` → `[WordDTO]` (search LIKE + FTS5 sau)
- `GET /content/words/{id}` → `WordDTO`
- `GET /content/sync?since=version` → `{decks: [], nodes: [], words: [], deleted: [], new_version}`
- `POST /content/import` (Admin API-Key) `multipart {file: csv/json}` → `{imported: 120, new_version: 13}`

**Progress/Sync (Bearer):**
- `GET /sync/pull?since=<token>` (token = ISO8601 `updated_at` cursor) → `{changes: {word_progress: [], stage_progress: [], attempts: []}, new_token: "2026-08-31T00:00:00Z", has_more: bool}`
- `POST /sync/push {operations: [{type: "upsert_word_progress", payload: {...}}]}` → `{ack: [opIds], conflicts: [{word_id, server_version, server_data}]}` | `409` với conflict list
- `GET /me/progress/summary` → `{total_learned, total_bookmarked, streak, next_reviews: []}`

**Error envelope:** `{code: "AUTH_EXPIRED" | "VALIDATION_ERROR" | "CONFLICT" | "NOT_FOUND", message: string, details?: object, request_id: uuid}` + `X-Request-ID` header.

Swift gen: `openapi-generator-cli generate -i backend/openapi.json -g swift5 -o VocabCraftApp/Core/Network/Generated`.

---

## 5. Offline-First Sync Strategy

**Write path (local-first):**
1. User `recordReview(wordId, isCorrect, responseTimeMs)` → `SRSRepositoryImpl` upsert `UserWordProgress(version+=1, updatedAt=now())` trên `UserProgressModelActor` (sẽ đổi thành `actor`).
2. `SyncEngine.enqueue(.upsertWordProgress(wordId))` lưu `SyncOperation(id: UUID, type: String, payload: JSON, attempts: Int, createdAt: Date, status: .pending)` vào SwiftData (persistent, survive kill).
3. Không chờ mạng, UI update ngay từ local.

**Push (when online):**
- Trigger: `NWPathMonitor.pathUpdate` → `.satisfied` + `scenePhase == .active` + sau mỗi `recordReview` + `BGTaskScheduler` 15m nếu có pending.
- `SyncEngine.pushBatch(limit: 50)` → `POST /sync/push` với `Authorization: Bearer access_token` (refresh nếu 401). Retry 3 lần exponential 1s/2s/4s cho 5xx; 429 respect `Retry-After`.
- Server upsert `ON CONFLICT (user_id, word_id) DO UPDATE SET ... WHERE excluded.version > user_word_progress.version` (optimistic locking). Trả `conflicts` nếu `server.version > local.version`.
- Client `ConflictResolver.resolve(local, server)` → last-write-wins: nếu `server.version > local.version` → overwrite local; nếu `version` bằng và `server.updatedAt > local.updatedAt` → keep newer. Giai đoạn sau merge `easeFactor` thay vì overwrite.

**Pull (delta):**
- `GET /sync/pull?since=lastSyncToken` (token = max `updated_at` đã ack, lưu `SyncMetadataStore`). Server `SELECT ... WHERE updated_at > :since ORDER BY updated_at LIMIT 200`.
- iOS upsert vào SwiftData trên background `ModelActor`. Lưu `new_token` sau khi apply xong (atomic). `has_more` → loop paginate.

**Content sync:**
- `GET /content/manifest` so `localVersion` (UserDefaults `content_version`) với `server.version`. Nếu `local < server`, `GET /content/sync?since=localVersion` hoặc download SQLite patch (giữ `DatasetEngine` read-only bundle + `ContentCache.sqlite` cho delta). Fallback bundle khi offline.
- Background: check manifest khi `app.foreground` + daily `BGTask`.

**Widget:** `WidgetCurrentState` trong App Group `group.com.hoojinguyen.vocabcraft` vẫn source of truth; `SyncEngine` cũng sync `WidgetCurrentState` để cross-device nhất quán; silent APNs `content-available:1` trigger `WidgetCenter.shared.reloadTimelines`.

**Failure modes:** queue giữ `attempts`, backoff, không xóa local khi push fail; pull idempotent; reset DB chỉ sau backup `.bak` (fix `SharedAppGroupContainer.swift:66-70` destructive reset).

---

## 6. iOS Codebase Health, Bugs & Performance

### 6.1 Bugs / Debt (đã verify qua explore)

- `AppContainer.swift:78` — `useSampleData ? SampleVocabularyDataSource() : SampleVocabularyDataSource()` copy-paste, production không bao giờ dùng `DatasetEngine`. Fix: `useSampleData ? SampleVocabularyDataSource() : DatasetEngineDataSource(engine)`.
- `AppContainer.swift:86-88` fallback `MockVocabularyRepository()` khi `datasetEngine==nil` che lỗi production — đổi thành `preconditionFailure` ở Debug, fallback chỉ ở `XCTest`.
- `DatasetEngine.swift:5` `@MainActor` + SQLite sync block main khi `fetchWordRecords(limit:100)` — refactor thành `actor DatasetEngine` với `withCheckedContinuation` + `DispatchQueue(label: "dataset.db", qos: .userInitiated)`.
- `VocabCraftApp.swift` `SharedAppGroupContainer.createContainer()` `catch` xóa DB không backup — thêm `FileManager.copyItem(at: storeURL, to: storeURL.bak)` trước khi `removeItem`.
- `UserProgressModelActor.swift:640`, `ReflexBlitzViewModel.swift:659`, `QuickReflexDrillViewModel.swift:551` — file length gần warning 700/ error 1200 — split.
- Thiếu `APIClient`, `AuthStore`, `SyncMetadata` — build mới.

### 6.2 Architecture Refactor

- Tách `AppContainer.swift:274` → `DIContainer` (resolve), `RepositoryFactory`, `UseCaseFactory`, `ViewModelFactory` theo `swift-architecture` skill; tuân `swift-api-design-guidelines` cho naming.
- `VocabularyRepositoryImpl.swift` map `WordRecord→Word` lặp mỗi hàm — tách `WordMapper`, `TopicDeckMapper`.
- `UserProgressModelActor` từ `@MainActor class` → `actor` (SE-0466 approachable concurrency), `nonisolated` cho sync helpers.
- Thêm `Domain/Protocols/NetworkProtocol` để mock offline trong `VocabCraftAppTests`.

### 6.3 Performance (baseline `docs/build-optimization.md` 24.8s clean, 1.1s incremental)

- Fix 4 slow expressions: `ReflexBlitzCardView.swift:588 (2255ms)`, `MixedDrillSectionViews.swift:109 (2237ms)`, `ReflexBlitzCardView.swift:274 (2005ms)`, `MixedDrillSectionViews.swift:255 (1443ms)` — tách subview, annotate explicit type, dùng `ViewBuilder` thay single expression.
- Enable `COMPILATION_CACHE_ENABLE_CACHING=YES`, `DEBUG_INFORMATION_FORMAT=dwarf`, `EAGER_LINKING=YES` cho Debug (audit đã đề xuất, chưa apply).
- `VocabularyView.swift:407` LazyVStack sticky search — giữ debounce đã có, thêm `prefetch` threshold, `headerScrollThreshold` -50 audit.
- `SwiftDataModels` add index `#Index<UserWordProgress>([\.nextReviewDate])` cho query `needsReview`.

### 6.4 Quality Gate (AGENTS.md §5)

- `swiftlint` 0 warnings (`.swiftlint.yml` đã config `type_body_length:400`, `file_length:700`), `swift test --filter LocalizationTests` bilingual parity, full `swift test` pass, Xcode 0 warnings.

---

## 7. New Features Ideas (beyond backend)

1. **Content Expansion** 50→2500 từ, 4→10 decks (Du lịch, Y tế, IELTS Speaking Part 2, TOEIC) qua import pipeline.
2. **AI Example & Collocation** backend generate `definition_vi`/`example_en/vi` + collocations cache, dùng `CollocationExtractor.swift` đã có.
3. **Enhanced SRS** `SRSEngine.swift:55` hiện `responseTimeMs<2500` → thêm `quality` từ `shadowPronunciationScore` + `hintLevel` + `retryCount`.
4. **Pronunciation v2** `SpeechKit/SpeechAssessmentService` feedback chi tiết thay string distance.
5. **Smart Review Filters** `PersonalVaultViewModel` filter `needsReview`/`mistakeCount>3` + sort `nextReviewDate`.
6. **Widget Live + Push** silent push trigger reload khi manifest bump hoặc streak reset.
7. **Streak & Gamification v2** weekly goal, XP leaderboard local, hook `CraftStreakCelebrationSheet`.
8. **Onboarding CEFR Placement** seed `UserWordProgress` ban đầu.
9. **Offline Search Upgrade** FTS5 virtual table hoặc `CoreSpotlight` index thay `LIKE %query%`.

---

## 8. Backlog Epics & Tickets (31 tickets, 94 points, 1pt≈3h)

**EPIC A — Backend Foundation (12pt)**
- A1 `P0 5pt` Scaffold FastAPI modular monolith + docker-compose (app/postgres/caddy) + Alembic
- A2 `P0 3pt` OpenAPI + Pydantic v2 + error envelope + structlog + X-Request-ID
- A3 `P0 2pt` Config `pydantic-settings` + `.env` + `/health` + healthcheck
- A4 `P1 2pt` CI ruff/mypy/pytest + docker build + pre-commit

**EPIC B — Content Platform (18pt)**
- B1 `P0 5pt` DB schema `topic_decks/nodes/words/definitions/node_words/sentences/reflex_drills` + migrations
- B2 `P0 5pt` CRUD `GET /content/*` + manifest + ETag
- B3 `P0 3pt` Import pipeline ingest `english_dataset.db` + CSV → Postgres bump version
- B4 `P1 3pt` Delta `GET /content/sync?since=version` + `content_manifest` checksum
- B5 `P1 2pt` `POST /content/import` admin API-Key guard

**EPIC C — Auth & Sync (27pt)**
- C1 `P0 5pt` Auth `register|login|refresh` JWT access15m/refresh30d + bcrypt + users table
- C2 `P0 8pt` `POST /sync/push` + `GET /sync/pull?since=` cho word/stage/attempts (optimistic locking)
- C3 `P0 5pt` iOS `APIClient` + `AuthInterceptor` + `KeychainStore`
- C4 `P0 8pt` iOS `SyncEngine` + `SyncOperation` queue + NWPathMonitor + BGTask
- C5 `P1 3pt` SchemaV3 `version/updatedAt/deletedAt` + ConflictResolver last-write-wins
- C6 `P2 3pt` Silent APNs trigger widget reload

**EPIC D — iOS Health & Bugs (13pt)**
- D1 `P0 2pt` Fix `AppContainer.swift:78` bug + guard Mock fallback chỉ XCTest
- D2 `P0 3pt` Refactor `DatasetEngine` `@MainActor` → `actor` off-main
- D3 `P1 3pt` Split `AppContainer:274` → DI factories
- D4 `P1 2pt` Fix `SharedAppGroupContainer:66-70` destructive reset → backup .bak
- D5 `P1 3pt` Split large files `ReflexBlitzViewModel:659`, `UserProgressModelActor:640`

**EPIC E — Performance (8pt)**
- E1 `P0 3pt` Fix 4 slow type-checking expressions (ReflexBlitzCardView, MixedDrillSectionViews)
- E2 `P1 1pt` Enable `COMPILATION_CACHE_ENABLE_CACHING=YES`, `DEBUG_INFORMATION_FORMAT=dwarf`, `EAGER_LINKING=YES`
- E3 `P1 2pt` `VocabularyView:407` virtualization audit + search debounce
- E4 `P1 2pt` `swiftlint` 0 warnings + `swift test` + re-benchmark

**EPIC F — Features & Growth (16pt)**
- F1 `P1 5pt` Content expansion 50→500 words, 4→6 decks via import
- F2 `P1 3pt` Smart Review filters UI
- F3 `P2 3pt` SRS v2 quality từ pronunciation + hintLevel
- F4 `P2 5pt` Onboarding CEFR placement test
- F5 `P2 2pt` Streak weekly goal + XP hook

**Thứ tự solo 6 tuần đầu (12h/tuần):** W1 A1+B1 → W2 B2+B3+D1+D2 → W3 C1+C3 → W4 C2+C4 → W5 D3+E1+E2 → W6 B4+F1. F2-F5 backlog sau W6.

---

## 9. Risks & Mitigations

- **Solo sync complexity cao** → làm `C3+C4` sau khi `D2` refactor actor xong; dùng last-write-wins đơn giản trước, merge logic sau.
- **Self-host ops overhead** → Docker Compose single VPS, backup pg_dump, Caddy auto-TLS; chưa cần k8s.
- **Migration mất data** → backup `.bak` trước khi Alembic/SwiftData lightweight migration; `AppMigrationPlan` đã có `SchemaV1→V2`, thêm `V3`.
- **Content scale** → import pipeline idempotent `ON CONFLICT DO UPDATE WHERE version < excluded.version`.

---

## 10. Success Criteria

- Backend `docker compose up` pass, `/health` 200, `/content/manifest` ETag cache, `pytest` >80% cho auth/content/sync.
- iOS offline-first: airplane mode vẫn học 500 từ cache, online sync delta <2s cho 50 ops, conflict 0 data loss, `swift test` 100% pass.
- Build clean <15s, `swiftlint` 0 warnings, `VocabCraftAppTests` + `CraftUIKitTests` pass.
- Backlog 31 tickets trong GitHub Projects với point/priority, wave 1 (A1+B1+B2+B3+D1+D2) done trong 2 tuần đầu.

---

## 11. References

- Current arch: `docs/superpowers/specs/2026-08-03-vocab-craft-ios-design.md`, `Package.swift`, `VocabCraftApp/App/DI/AppContainer.swift`, `VocabCraftApp/Core/Database/DatasetEngine.swift`, `VocabCraftApp/Core/Database/SwiftDataModels.swift`, `docs/build-optimization.md`.
- Skills: `swift-architecture`, `swift-concurrency`, `swiftdata`, `swiftdata-pro`, `xcode-build-orchestrator`.
