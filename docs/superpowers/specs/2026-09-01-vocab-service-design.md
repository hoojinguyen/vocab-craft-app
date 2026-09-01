# VocabCraft Foundation & Service Platform — High-Level Solution Design (Source of Truth)

**Date:** 2026-09-01
**Status:** Approved — Source of Truth for entire development lifecycle (supersedes `2026-08-31-vocabcraft-backend-platform-design.md`)
**Author:** OpenCode (Muse Spark) + hoojinguyen
**Approach:** Hybrid (Content offline-first via SQLite bundled + Progress cloud) — Modular FastAPI + Postgres + Ollama self-host on Mac mini M4
**Scope:** Foundation vững chãi cho sản phẩm thực tế (không phải MVP/POC). Tách biệt Service quản lý tiến độ học, từ vựng, mẫu câu. Pipeline 0-đồng → CMS human/AI → SQLite bundled → API + background sync. Lộ trình AI theo phase.
**Process:** Spec này là high-level solution design duy nhất. Không chứa implementation plan chi tiết. Mỗi phase trong §12 sẽ được brainstorm riêng để ra spec chi tiết + plan trước khi thực thi.

---

## 1. Executive Summary

VocabCraft hiện tại là SwiftUI + CraftUIKit + SpeechKit (~25.6k LOC, 160 files) với `AppContainer.swift:7` là composition root, `DatasetEngine.swift:4` đọc SQLite readonly `english_dataset.db` (đang fallback `SampleVocabularyDataSource` 50 từ), tiến độ lưu local qua `UserProgressModelActor:87` + `SRSRepositoryImpl` + `SRSEngine.swift:15`. Chưa có backend, chưa có dataset thật, chưa có sync, chưa release.

Mục tiêu: xây **móng vững** cho sản phẩm thực tế, có thể scale 3000→10000+ từ, offline tốt, sync đa thiết bị, không tốn API bên thứ 3 cho pipeline. Thay vì làm MVP cho có, ta tách 2 thành phần, làm pipeline chuẩn hoá dataset trước, CMS human/AI duyệt, khi dataset đủ tốt mới build API và SQLite bundled, cuối cùng tích hợp iOS với background sync để UX không bị block.

Quyết định duyệt:
- Không migrate sample — build dataset mới hoàn toàn trên internet sources uy tín, ≥3000 từ A1-B2 chuẩn trước release.
- Stack B: Python FastAPI (ưu tiên crawl/NLP/AI pipeline).
- Self-host 100% trên Mac mini M4, Ollama model nhẹ (<4GB).
- Hybrid: Content SQLite bundled (transform từ Postgres) + Progress sync cloud background (không phải cloud-first thuần).

---

## 2. Goals, Non-Goals, Constraints & Principles

**Goals (v1 release):**
- G1: Dataset chuẩn ≥3000 từ (lemma, POS, IPA US/UK, CEFR, definition EN/VI, example EN/VI, collocation EN/VI, audio URL) có provenance, qua human review, sẵn sàng bundled + serve delta.
- G2: Tách biệt Service: Data Platform (pipeline + CMS + SQLite builder) và API Platform (Content API + Progress API + Auth).
- G3: Trải nghiệm tốt nhất: content đọc từ SQLite local 0ms, user progress sync nền không block UI, offline học được, online tự reconcile <2s/50 ops.
- G4: CMS admin-only duyệt chất lượng, quản lý decks/nodes, theo dõi confidence.
- G5: Pipeline 0 đồng API trả phí (chỉ open-source + Ollama self-host).
- G6: iOS giữ Clean Architecture, chỉ đổi Repository Impl, không đụng ViewModel, CraftUIKit-first, bilingual parity.

**Non-Goals (v1):**
- Không microservices/k8s/Redis/Realtime/social leaderboard. Một modular monolith đủ.
- Không AI tutor/interaction runtime trong v1 (chỉ pipeline AI). AI tutor để post-release khi đã có user.
- Không multi-tenant CMS, không FTS5, không train LLM riêng.

**Constraints:**
- Solo dev full-stack, 2 tháng cho dataset + API core (để release), sau đó iterate.
- Self-host Mac mini M4 (16GB), Ollama lightweight (`qwen2.5:1.5b/3b`, `nllb-200-distilled-600M`, `wordfreq`, `spaCy en_core_web_sm`, `epitran`).
- Quality gate `AGENTS.md §5`: `swiftlint` 0, `swift test` pass (LocalizationTests), Xcode 0 warnings, `pytest` >70% cho backend, `/health` 200.

**Principles (móng vững):**
- **P1 — Contract-first:** DB schema + OpenAPI + Swift DTOs lock ở Foundation trước khi crawl. Tránh đổi schema khi đã có 3000 từ.
- **P2 — Provenance & versioning:** mọi word/definition ghi `source_url`, `version`, `updated_at`, `status` (`pending→ai_reviewed→human_approved→rejected`), `content_manifest.version` để delta.
- **P3 — Idempotent & audit:** pipeline jobs lưu `raw_payload/normalized_payload/ai_review` JSONB, import `ON CONFLICT DO UPDATE WHERE version < excluded.version`.
- **P4 — YAGNI:** không thêm infra/pattern khi chưa cần. Một Postgres, một FastAPI, một Ollama.
- **P5 — UX-first:** content offline-first, progress optimistic local + background reconcile (server-wins nhưng app đã tính SRS local để UI mượt).

---

## 3. High-Level Architecture

### 3.1 Context (C4 Level 1)

```
[User iOS App] ──(1) read SQLite bundled──▶ [SQLite vocab_dataset.sqlite (bundled + delta)]
       │                (2) background sync manifest/bundle
       │                (3) background sync progress (push/pull)
       ▼
[API Platform — FastAPI :8000 behind Caddy :443] ◀──(4) CMS approve── [Admin (human) via CMS]
       │                ▲
       │                │ (5) transform Postgres → SQLite
       ▼                │
[Postgres 16 — source of truth for content+progress]
       ▲
       │ (6) pipeline jobs
[Data Platform — Pipeline + CMS]
       │ (7) Ollama :11434 (qwen2.5:3b, nllb-600M) — only Data Platform calls
```

### 3.2 Components (C4 Level 2) — 2 thành phần chính như bạn yêu cầu

**Thành phần 1: Data Platform (không serve user trực tiếp, chỉ admin + batch)**
- **Pipeline Service:** `Crawler` (Trafilatura/Wiktionary dump/Tatoeba) → `Cleaner` (ftfy, langdetect, dedup) → `Normalizer` (spaCy POS, epitran IPA, wordfreq CEFR/frequency) → `Translator` (NLLB local) → `AI Reviewer` (Qwen2.5:3b, JSON confidence/issues). Input: lemma list (wordfreq top). Output: `pipeline_jobs` row (`pending→crawling→normalizing→translating→ai_reviewing→human_queue`). Chạy batch 50, `temperature 0.2`, `num_ctx 2048`, một model tại một thời điểm để tiết kiệm RAM M4.
- **CMS Service:** `Review Queue` (filter `human_queue` ưu tiên confidence <0.75, `ai_reviewed` batch), `Deck/Node Editor`, `Approve/Reject` (khi approve → upsert `words/definitions` `status=human_approved`, bump `content_manifest.version`, tính `checksum`). Guard `X-Admin-Key` + admin JWT.
- **SQLite Builder:** Job `build_sqlite --version X` → `SELECT ... WHERE status=human_approved AND deleted_at IS NULL` từ Postgres → tạo `vocab_dataset.sqlite` (schema tương thích `DatasetEngine`) + `manifest.json {version, checksum, total_words, total_decks}`. Upload tới `storage/bundles/v{version}.sqlite` và serve qua `GET /content/bundle?version=`. Đây là cầu nối giữa Data Platform và API Platform.

**Thành phần 2: API Platform (serve app + admin)**
- **Content API (public, cached):** `manifest`, `bundle`, `decks/nodes/words` (chỉ `human_approved`), `sync?since_version` (delta JSON cho app patch SQLite thay vì download full). ETag + `Cache-Control: public, max-age=300` cho manifest.
- **Progress API (Bearer):** `review/bookmark/drill/stage_complete`, `summary/history`, `sync/push|pull` (cursor `updated_at` ISO8601, server-wins). SRS tính server (port `SRSEngine.swift:15`) nhưng app cũng tính optimistic local để UI không chờ.
- **Auth API:** `register/login/refresh/me` (JWT access 15m/refresh 30d, bcrypt, rate limit 100/60s/IP in-memory).
- **Core:** `Caddy` TLS Let's Encrypt, `X-Request-ID` mọi response, error envelope `{code, message, details, request_id}`, `structlog`, `slowapi`.

Cả 2 thành phần chung Postgres nhưng deploy cùng container ở v1 (modular monolith `app/modules/{auth,vocabulary,decks,progress,cms,pipeline}`). Khi scale mới tách pipeline thành worker riêng — không cần ngay.

### 3.3 Deployment (Mac mini M4)

- `docker compose up --build` — `app:8000`, `postgres:16` (`pgdata` volume), `caddy:80/443` (auto TLS, `Caddyfile` reverse_proxy), `ollama:11434` (`ollama_models` volume, `ollama pull qwen2.5:3b && nllb-200-distilled-600M` <4GB). Ollama không expose ra internet, chỉ `app` gọi `http://ollama:11434/api/generate`.
- Không Redis v1. Backup `cron pg_dump -Fc > /backups/pg-$(date +%F).dump` daily, retain 7d, rclone offsite.
- `openapi.json` generate từ Pydantic, dùng để gen Swift DTOs (`swift-openapi-generator` hoặc `openapi-generator-cli`).

### 3.4 Repo Layout (high-level)

```
vocab-craft-app/                  # iOS (giữ nguyên, thêm Core/Network + Core/Sync)
vocab-craft-api/                  # Data + API Platform (tách repo riêng để CI độc lập, hoặc backend/ trong monorepo — chọn tách repo)
  app/{core, modules/{auth,vocabulary,decks,progress,cms,pipeline}, api/v1}
  alembic/
  scripts/{crawl.py, build_sqlite.py, seed.py}
  Dockerfile, docker-compose.yml, Caddyfile, .env.example, openapi.json
```

---

## 4. Data Architecture — Source of Truth & Bundled Artifact

### 4.1 Postgres (source of truth)

**Content (versioned, soft-delete, chỉ `human_approved` mới public):**
- `words(id BIGINT PK, lemma TEXT UNIQUE, pos, ipa_us, ipa_uk, cefr_level CHECK A1..C2, frequency_rank, audio_url, status CHECK pending/ai_reviewed/human_approved/rejected, ai_confidence DOUBLE, source_url, created_at, updated_at, version, deleted_at)`
- `definitions(id BIGINT PK, word_id FK, pos, definition_en, definition_vi, definition_vi_auto, example_en, example_vi, collocation_en/vi, source_url, status, version, updated_at)`
- `sentences(id BIGINT PK, word_id FK, text_en, text_vi, cefr_level, source)`
- `reflex_drills(id BIGINT PK, sentence_id FK, drill_type, prompt_text, correct_answer, distractors_json JSONB, target_time_ms)`
- `topic_decks(id TEXT PK, title, title_vi, icon_name, badge_color_hex, cefr_level, sort_order, status, version, updated_at)`
- `topic_nodes(id TEXT PK, deck_id FK, title, title_vi, icon_name, sort_order, version)`
- `node_words(node_id FK, word_id FK, sort_order, PK(node_id, word_id))`
- `content_manifest(version INT PK, checksum TEXT, total_words, total_decks, created_at)` — bump khi CMS approve.
- `pipeline_jobs(id UUID PK, lemma TEXT, status CHECK pending/crawling/.../approved/rejected, raw_payload JSONB, normalized_payload JSONB, ai_review JSONB {confidence, issues, suggested}, assigned_to, created_at, updated_at)`

**Progress (cloud source of truth, per-user):**
- `users(id UUID PK, email UNIQUE, password_hash, display_name, created_at)`
- `user_word_progress(user_id FK, word_id FK, mastery_level 0..5, ease_factor, interval_days, next_review_date, last_review_date, is_bookmarked, mistake_count, consecutive_streak, practiced_modes TEXT, mode_success_counts TEXT, is_mastered, source_deck_id, source_node_id, total_reviews, version, updated_at, deleted_at, PK(user_id, word_id))` + index `next_review_date` + `updated_at`
- `user_stage_progress(user_id, stage_id TEXT, deck_id FK, is_completed, score, progress_fraction, completed_at, version, PK(user_id, stage_id))`
- `quick_reflex_attempts(id UUID PK, user_id FK, word_id FK, drill_type, recall_time_ms, produce_time_ms, shadow_score, hint_level, input_mode, is_correct, response_time_ms, created_at)` + index `(user_id, word_id, created_at DESC)`
- `streaks(user_id PK FK, current_streak, longest_streak, last_active_date, total_xp)`

Mapping iOS: `Word.swift:4` ↔ `words+definitions`, `TopicDeckEntities` ↔ `topic_decks/nodes`, `UserWordProgressData:27` ↔ `user_word_progress` (+ `version/updatedAt` khi cache ở SwiftData SchemaV3).

### 4.2 SQLite Bundled (artifact, không phải source of truth)

- Schema SQLite **tương thích** `DatasetEngine.swift:5` hiện tại (để `VocabCraftApp` không phải đổi nhiều): `words`, `definitions`, `topic_decks`, `topic_nodes`, `node_words`, thêm bảng `manifest(version INT, checksum TEXT)` để app biết bundled version (seed từ `content_manifest`).
- Build: `build_sqlite.py --version X` chạy `SELECT ... WHERE status=human_approved` → `sqlite3` tạo file `VocabCraftApp/Resources/vocab_dataset.sqlite` (cho IPA build) và `storage/bundles/vX.sqlite` (cho delta download). Tính `sha256` → update `content_manifest.checksum`.
- Kích thước dự kiến: 3000 từ + definitions + 8 decks ≈ 3-5MB SQLite, chấp nhận bundle trong IPA.
- Delta: app đã có `v12`, server có `v13` → `GET /content/sync?since_version=12` trả JSON delta (`words: [], deleted: []`, `new_version: 13`) để app apply vào SQLite local qua `ContentCache` (không cần download full 5MB mỗi lần). Full bundle chỉ khi cài mới hoặc major bump.

---

## 5. Service Boundaries & Contracts (high-level)

| Service | Trách nhiệm | Không làm | Contract |
|---------|-------------|-----------|----------|
| **Auth** | register/login/refresh, JWT, bcrypt, `users` | Không đụng content/progress | `POST /auth/*`, `GET /auth/me` |
| **Vocabulary** | CRUD words/definitions/sentences, search ILIKE, `status` filter, version | Không tính SRS | `GET /content/words`, `GET /content/words/{id}` |
| **Decks** | topic_decks/nodes/node_words, sort_order, manifest | Không lưu mastery | `GET /content/decks`, `GET /content/decks/{id}/nodes`, `GET /content/nodes/{id}/words`, `GET /content/sync?since_version`, `GET /content/bundle?version=` |
| **Progress** | SRS (`srs.py` port `SRSEngine.swift:15`), mastery/ease/interval/next_review, streak/xp, bookmark, weak-words, history | Không serve content raw | `POST /progress/words/{id}/review`, `bookmark`, `drill`, `stages/{id}/complete`, `GET /progress/summary`, `POST /sync/push`, `GET /sync/pull?since=` |
| **CMS** | admin guard, review queue, approve/reject, bump manifest, import | Không gọi Ollama trực tiếp | `GET /admin/pipeline/jobs?status=`, `POST /admin/pipeline/jobs/{id}/approve`, `POST /admin/content/import` |
| **Pipeline** | crawl→clean→normalize→translate→AI review (async job) | Không expose public, chỉ `POST /admin/pipeline/trigger` | Internal, ghi `pipeline_jobs` |

Dependency rule: `progress` đọc `words` (FK check) không ghi `words`; `cms` ghi `words/definitions`; `pipeline` ghi `pipeline_jobs` + draft `words/pending`. Tất cả qua `core/db.py` session.

**High-level API contract (OpenAPI 3.1, Pydantic v2 → Swift Codable ISO8601):**

- Auth public, Content public (ETag, chỉ `human_approved`), Progress Bearer (server là source of truth nhưng app optimistic), CMS Admin (`X-Admin-Key` + admin role).
- Error envelope thống nhất: `{code: AUTH_EXPIRED|VALIDATION_ERROR|CONFLICT|NOT_FOUND|RATE_LIMITED, message, details?, request_id}` + `X-Request-ID`.
- OpenAPI → Swift: `swift-openapi-generator` generate DTOs, không hardcode.

---

## 6. Dataset Pipeline — 0 Đồng (high-level)

**Nguồn (chỉ CC-BY-SA/CC-BY, ghi `source_url`):**
- Frequency: `wordfreq` top 5000 en → top 3000.
- Definition/Example: Wiktionary dump `enwiktionary-latest-pages-articles.xml.bz2`, Oxford 3000 wordlist (public domain extract), Tatoeba sentences.
- IPA: `epitran`/`eng_to_ipa` rule-based.
- CEFR: heuristic `wordfreq` + `zipf_frequency` + Cambridge Vocabulary Profile public list (không LLM).
- Dịch VI: `nllb-200-distilled-600M` local via Ollama.

**DAG (mỗi lemma 1 job, batch 50):**
1. Crawler (Trafilatura/BeautifulSoup) — `raw_html`, `raw_definition_en`, `source_url`.
2. Cleaner (ftfy, `clean-text`, langdetect filter en, dedup).
3. Normalizer (spaCy `en_core_web_sm` POS, epitran IPA, wordfreq CEFR/frequency_rank).
4. Translator (NLLB) — `definition_vi_auto`, `example_vi_auto`.
5. AI Reviewer (Qwen2.5:3b, prompt JSON `confidence 0..1, issues[], suggested_definition_vi, cefr_correct`) — routing: `confidence >=0.75 → ai_reviewed` (chờ batch human, ưu tiên thấp), `<0.75 → human_queue` ưu tiên cao. Chưa auto-approve ở bước này.
6. Human Queue (CMS) — approve → `human_approved` + bump manifest, reject → `rejected`. CMS UI Jinja đơn giản, side-by-side EN/VI + ai_review.

**Quality gate trước khi qua API (Phase 2 exit criteria):**
- Random 10% (300 từ) human duyệt 100% bất kể confidence.
- 90% còn lại: `confidence ≥0.85` mới auto-approve lên `human_approved` không cần human, `0.75-0.84` phải qua `human_queue` batch duyệt nhanh, `<0.75` bắt buộc human chi tiết.
- Tổng `human_approved` ≥3000, mỗi entry có `definition_vi` (human hoặc NLLB+AI suggest đã duyệt), `example_en/vi`, `ipa_us`, `cefr_level`, `source_url`.

**Thứ tự seed:** Wave 1 (1000) A1-A2 core (Oxford 3000 A1+A2 ∩ wordfreq top 1500) → Wave 2 (1000) B1 (1500-2500) → Wave 3 (1000) B2 (2500-4000, lọc academic).

**Thực thi:** `APScheduler` hoặc polling Postgres `pipeline_jobs` mỗi 5s (Redis-free), trigger `POST /admin/pipeline/trigger {lemmas}` hoặc `scripts/crawl.py --wave 1`. Lưu `raw_payload/normalized_payload/ai_review` JSONB để audit.

---

## 7. CMS — Human Chuẩn Hoá

- Review queue filter `status=human_queue` sort `ai_confidence ASC` (ưu tiên thấp confidence trước), hiển thị `lemma`, `pos`, `definition_en`, `definition_vi_auto`, `suggested_definition_vi`, `issues`, `source_url`.
- Actions: Approve (1 click), Reject (require reason), Edit (sửa `definition_vi`/`example_vi` trước khi approve). Batch approve cho `confidence ≥0.85` (checkbox).
- Deck/Node editor: CRUD `topic_decks/nodes`, drag `sort_order`, assign `node_words` (chọn từ `human_approved`).
- Import: `POST /admin/content/import` multipart CSV/JSON (idempotent).
- Auth: `X-Admin-Key` 32+ chars, chỉ Mac mini biết, không expose CMS ra public internet (Caddy basic auth hoặc Tailscale).

---

## 8. SQLite Builder & Distribution

- **Build:** `build_sqlite.py --version X` như §4.2. Chạy sau mỗi lần CMS approve batch (có thể trigger manual `POST /admin/content/build` ở v1, sau này cron).
- **Distribution:**
  - **Bundled:** file `vocab_dataset.sqlite` kèm IPA (build time). `DatasetEngine.swift:4` vẫn `Bundle.main.path(forResource: "vocab_dataset", ofType: "sqlite")` — không đổi View.
  - **Delta OTA:** `GET /content/manifest` (app check mỗi `app.foreground` + daily BGTask) → nếu `server.version > local_version` (lưu `UserDefaults content_version` + `manifest` table) → `GET /content/sync?since_version=local` (JSON delta, <100KB) → app apply vào `ContentCache.sqlite` (copy của bundled, writable trong `Application Support`). Fallback bundled khi offline.
  - **Full OTA (hiếm):** `GET /content/bundle?version=13` (5MB) chỉ khi delta quá lớn hoặc fresh install muốn latest không cần App Store update.
- **Versioning:** `content_manifest` bump mỗi approve, `checksum` để app verify integrity sau khi apply delta.

---

## 9. API Platform — High-Level

**Content API (public, cached, chỉ `human_approved`):**
- `GET /content/manifest` → `{version, checksum, total_words, total_decks, created_at}` (ETag, `max-age=300`).
- `GET /content/bundle?version=` → binary SQLite (optional).
- `GET /content/decks`, `GET /content/decks/{id}/nodes`, `GET /content/nodes/{id}/words`, `GET /content/words?limit=&q=&cefr=` (ILIKE v1, FTS5 sau), `GET /content/words/{id}`, `GET /content/sync?since_version=`.

**Progress API (Bearer, server source of truth nhưng app optimistic):**
- `GET /progress/words`, `GET /progress/words/{id}`, `POST /progress/words/{id}/review {is_correct, response_time_ms, drill_type?, hint_level?}` → `{progress, srs {next_mastery, ease_factor, interval_days, next_review_date}, streak, xp_delta}` (server chạy `srs.py` port `SRSEngine`, bump `version`, tính `next_review`).
- `POST /progress/words/{id}/bookmark` (idempotent toggle), `POST /progress/words/{id}/drill`, `POST /progress/stages/{id}/complete`, `GET /progress/summary`, `GET /progress/history?word_id=`.
- `POST /progress/sync/push {operations: [{op_id, type, payload, client_version}]}` → `{acks, conflicts}` (server-wins), `GET /progress/sync/pull?since=ISO8601` → `{changes, new_token, has_more}` (cursor `max updated_at`).

**Auth:** `POST /auth/register|login|refresh`, `POST /auth/logout`, `GET /auth/me`.

---

## 10. iOS App Integration — Background Sync, UX Không Block

**Tối thiểu đụng chạm:** Giữ `Domain/Protocols/*` (đã có `UserProgressRepositoryProtocol`, `VocabularyRepositoryProtocol`), thêm `RemoteVocabularyRepository`/`RemoteProgressRepository`/`RemoteDeckRepository` gọi `APIClient`, `AppContainer.swift:7` inject `apiClient: APIClient` (URLSession async/await, `Endpoint` enum, `AuthInterceptor` refresh 401→ retry 1 lần, `RetryPolicy` exponential 1s/2s/4s, `X-Request-ID`), `AuthStore` (Keychain `kSecClassGenericPassword`, `kSecAttrAccessibleAfterFirstUnlock`), `DTOs` gen từ `openapi.json`. Không đụng ViewModel.

**Content đọc:**
- App launch → đọc `vocab_dataset.sqlite` bundled (hoặc `ContentCache.sqlite` đã patch) qua `DatasetEngine` (sẽ refactor `@MainActor` → `actor` off-main queue ở phase Foundation) → UI hiện ngay 0ms.
- Background: `SyncEngine` check `GET /content/manifest` mỗi foreground + daily `BGTask`, nếu `new_version` → `GET /content/sync?since_version` → apply delta vào `ContentCache.sqlite` (background `ModelActor`), update `manifest` table, không block UI. Thất bại thì giữ bundled.

**Progress ghi:**
- User `markWordReviewed` → ViewModel gọi `EvaluateSRSUseCase.recordReview` → đổi thành `RemoteProgressRepository.review` nhưng **optimistic local** trước: tính `SRSEngine` local để UI update tức thì (mastery + next_review tạm), đồng thời `SyncEngine.enqueue(.review)` vào SwiftData `PendingOps` (persistent, survive kill) với `op_id` UUID.
- Flush queue background: `NWPathMonitor.satisfied` + `scenePhase==.active` + sau mỗi enqueue + `BGTaskScheduler` 15m nếu có pending → `POST /sync/push` batch 50 → server trả canonical `progress` (server-wins), app reconcile: overwrite local `UserWordProgress` với server `version/updated_at` mới, không tăng mastery vượt server. Nếu conflict (`client_version < server.version`) → server trả `conflicts`, app discard local, apply server.
- Pull delta: `GET /sync/pull?since=lastSyncToken` (lưu `SyncMetadataStore` UserDefaults + SwiftData atomic), upsert vào SwiftData/Widget `App Group` trên background, loop nếu `has_more`, rồi `WidgetCenter.reloadTimelines()`.

**Widget & Notifications:** `WidgetCurrentState` trong `App Group group.com.hoojinguyen.vocabcraft` update từ local cache sau pull. Silent APNs `content-available:1` khi CMS bump manifest trigger `BGTask` pull (optional v1).

---

## 11. Cross-Cutting Concerns

**Security:** Keychain cho tokens, không lưu password, `X-Admin-Key` 32+ chars, rate limit in-memory 100/60s/IP, `X-Request-ID` trace.

**Observability:** `structlog` JSON, log `request_id`, `user_id`, `duration`, health `/health` + `/api/v1/health`, `Caddy` access log.

**Backup:** `pg_dump -Fc` daily, retain 7d, rclone offsite, `SharedAppGroupContainer` backup `.bak` trước khi SwiftData migration (fix destructive reset).

**Performance:** Content đọc local <50ms, search SQLite ILIKE 50 từ <100ms (FTS5 sau), `swiftlint` type_body_length/file_length, tách subview cho `ReflexBlitzCardView:588` slow expressions, `COMPILATION_CACHE_ENABLE_CACHING=YES`, `DEBUG_INFORMATION_FORMAT=dwarf` cho Debug, `SwiftData #Index(nextReviewDate)` cho `needsReview`.

**Localization:** `Localizable.xcstrings` `craft.*` + `app.*`, bilingual EN/VI 100%, `manual` + `translated`, format specifier parity.

---

## 12. Phases & Exit Criteria (high-level, mỗi phase sẽ brainstorm riêng)

**Phase 0 — Foundation (1 tuần):**
- Lock DB schema (Alembic V1) + OpenAPI contract + Swift DTOs + tooling (ruff/mypy/pytest, swiftlint, docker-compose, Caddy, pg backup, X-Request-ID, error envelope).
- Exit: `docker compose up` pass, `/health` 200, `openapi.json` gen ra Swift DTOs compile, `pytest`/`swift test` pass.

**Phase 1 — Pipeline thô (2-3 tuần):**
- Crawler/cleaner/normalizer chạy được 50 lemmas batch, ghi `pipeline_jobs`.
- Exit: `crawl.py --wave 1 --limit 50` chạy end-to-end (crawl→clean→normalize) không lỗi, 50 jobs `human_queue|ai_reviewed`.

**Phase 2 — Translator + AI Reviewer + CMS (2 tuần, song song Phase 1):**
- NLLB + Qwen qua Ollama, CMS review queue (filter, approve/reject, edit), bump `content_manifest`.
- Exit: 300 từ đầu `human_approved` (100% human cho 10% random), CMS approve 1 job → `GET /content/manifest` version tăng.

**Phase 3 — SQLite Builder + Content/Progress API (2-3 tuần):**
- Builder tạo `vocab_dataset.sqlite` từ Postgres, Content API public, Progress API Bearer với SRS port.
- Exit: `build_sqlite --version X` tạo file 3-5MB, `pytest` >70% cho auth/content/progress, `srs.py` khớp `SRSEngine.swift:15` (test `response_time <2500` quality), `docker compose up` + `curl /content/manifest` + `curl /progress/summary` (với token) 200.

**Phase 4 — iOS Integration (1-2 tuần):**
- `APIClient/AuthStore/Remote Repos/AppContainer`, `SyncEngine` queue + background + server-wins, `ContentCache` delta apply.
- Exit: TestFlight internal: login/register hoạt động, đọc 3000 từ từ SQLite 0ms, bookmark/review optimistic + background reconcile, airplane mode học được, online flush 50 ops <2s, `swiftlint` 0, Xcode 0 warnings.

**Phase 5 — Seed 3000 & Release (2 tuần, overlap Phase 3-4):**
- Wave 1 A1-A2 (1000) → Wave 2 B1 (1000) → Wave 3 B2 (1000), quality gate §6.
- Exit: `SELECT COUNT(*) WHERE human_approved >=3000`, mỗi entry có `definition_vi`, `example_vi`, `ipa_us`, `cefr`, `source_url`, `vocab_dataset.sqlite` bundled trong IPA, TestFlight release.

**Post-release AI (phase riêng, sau khi có user, brainstorm sau):**
- Phase 6: Adaptive SRS (logistic regression trên `quick_reflex_attempts`, không LLM).
- Phase 7: Pronunciation v2 (Wav2Vec2 small local).
- Phase 8: Chat role-play (Qwen 7B trên Mac mini, SSE, chỉ khi >1000 DAU).

---

## 13. Decisions & Risks

**ADR:**
- ADR-1: Hybrid SQLite bundled + background sync thay vì cloud-first thuần — vì UX 0ms, offline, và transform Postgres→SQLite là best practice cho content-heavy app (như Duolingo).
- ADR-2: Modular monolith thay vì microservices — solo dev, 2 tháng, một deploy, folder `modules/*` đủ để sau tách worker.
- ADR-3: Ollama self-host (`qwen2.5:3b` + `nllb-600M`) thay vì API trả phí — 0 đồng, phù hợp M4, chạy 1 model tại một thời điểm để tiết kiệm RAM.
- ADR-4: `content_manifest.version` integer monotonic + `checksum` thay vì timestamp — đơn giản cho delta.
- ADR-5: Server-wins cho progress conflict ở v1 (đơn giản), không merge `easeFactor` phức tạp.

**Risks:**
- Solo sync complexity → server-wins + optimistic local + flush queue đơn giản, không merge.
- Ollama M4 memory → chỉ 1 model/1 batch 50.
- Crawl legal → chỉ CC-BY-SA/CC-BY, ghi `source_url`, langdetect filter.
- Self-host ops → Docker Compose single host, pg_dump daily, Caddy auto-TLS.

---

## 14. Success Criteria (v1 Release — Source of Truth)

- Data Platform: `pipeline_jobs` 3000+ lemmas processed, `human_approved` ≥3000 với quality gate §6, `content_manifest.total_words=3000`, SQLite 3-5MB verify `sha256`.
- API Platform: `docker compose up` pass, `openapi.json` gen Swift DTOs, `pytest` >70%, `/health` 200, ETag, `X-Request-ID`.
- iOS: TestFlight đọc SQLite 0ms, progress persist server, airplane mode học được, online sync <2s/50 ops, `swift test` 100% pass, `swiftlint` 0.
- Foundation: Alembic V1, OpenAPI lock, tooling pass, không đổi schema giữa chừng.

---

## 15. References & Next Steps

- Current: `VocabCraftApp/App/DI/AppContainer.swift`, `VocabCraftApp/Core/Database/DatasetEngine.swift`, `VocabCraftApp/Core/SRS/SRSEngine.swift`, `VocabCraftApp/Domain/Protocols/*`, `VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift`, `docs/build-optimization.md`, `Package.swift`.
- Superseded: `2026-08-31-vocabcraft-backend-platform-design.md`.
- Skills: `swift-architecture`, `swift-concurrency`, `swiftdata-pro`, `xcode-build-orchestrator`, `swiftlint`.

**Next steps (bạn sẽ tự lên plan):**
1. Duyệt spec high-level này.
2. Brainstorm riêng từng phase (Phase 0 Foundation trước) để ra spec chi tiết + plan task nhỏ (mỗi phase ≤8pt/task, TDD).
3. Sau Phase 0 lock contract, mới tiến hành Phase 1 pipeline — đảm bảo móng vững xuyên suốt.

