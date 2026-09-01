# VocabCraft Cloud-First Service & Dataset Platform — Technical Design Specification

**Date:** 2026-09-01
**Status:** Draft — Approved, Pending Implementation Plan
**Author:** OpenCode (Muse Spark) + hoojinguyen
**Approach:** Cloud-First Monolithic FastAPI (Python) + Postgres + Ollama Self-Host on Mac mini M4
**Scope:** Tách biệt Service quản lý tiến độ học, từ vựng, mẫu câu + Lộ trình Dataset ≥3000 từ + Lộ trình AI
**Related:** `2026-08-31-vocabcraft-backend-platform-design.md` (superseded — chuyển từ offline-first sang cloud-first)

---

## 1. Executive Summary

VocabCraft hiện tại chỉ có UI/UX + sample data. `AppContainer.swift:7` là composition root duy nhất, `DatasetEngine.swift:4` đọc SQLite readonly `english_dataset.db` (đang fallback `SampleVocabularyDataSource`), tiến độ lưu local qua `UserProgressModelActor:87` + `SRSRepositoryImpl` + `SRSEngine:15`. Chưa có backend, chưa có sync, chưa có dataset thật.

Mục tiêu spec này: định nghĩa kiến trúc **tách biệt Service** theo hướng **Cloud-first** (server là source of truth, app là thin client có cache), xây **dataset pipeline 0 đồng API bên thứ 3** để có **≥3000 từ chuẩn trước release**, và lộ trình AI theo phase. Thiết kế tối ưu cho **solo dev full-stack, 2 tháng cho dataset + API core**, deploy **self-host 100% trên Mac mini M4 với Ollama model nhẹ**.

Quyết định then chốt đã duyệt:
- Không migrate sample — build dataset mới hoàn toàn.
- Stack B: Python FastAPI (ưu tiên crawl/NLP).
- AI bắt đầu từ Content Pipeline (rẻ, chuẩn dataset), AI tutor/interaction để post-release.

---

## 2. Goals, Non-Goals & Constraints

**Goals (v1 release):**
- G1: Dataset chuẩn ≥3000 từ (lemma, POS, IPA US/UK, CEFR A1-C1, definition EN/VI, example EN/VI, collocation EN/VI, audio URL) có nguồn uy tín, qua human review, sẵn sàng serve qua API.
- G2: Service tách biệt quản lý: Vocabulary + Sentences/Collocations + Decks/Nodes + User Progress (SRS, mastery, bookmark, streak, XP, drill history, weak words) + Auth + CMS Admin.
- G3: Cloud-first: mọi write qua API, server là source of truth; app cache SQLite chỉ để read-through + offline queue (không phải source of truth), sync khi online <2s cho 50 ops.
- G4: CMS admin-only để duyệt dataset, quản lý decks/nodes, theo dõi pipeline confidence.
- G5: Pipeline 0 đồng: crawl/normalize/dịch/đánh giá chất lượng không gọi API trả phí (chỉ self-host Ollama + open-source).
- G6: App integration giữ Clean Architecture hiện có, chỉ đổi Repository Impl (giữ Protocol), không đụng ViewModel.

**Non-Goals (v1):**
- Không microservices, không Kubernetes, không Redis, không Realtime multiplayer/leaderboard server.
- Không AI tutor/interaction runtime trong v1 (chỉ pipeline AI).
- Không multi-tenant CMS (chỉ 1 admin role).

**Constraints:**
- Solo dev full-stack, 2 tháng.
- Self-host Mac mini M4 (Ollama lightweight: `qwen2.5:1.5b` hoặc `3b`, `nllb-200-distilled-600M` cho VI, `wordfreq`/`spaCy` local).
- Bilingual parity `Localizable.xcstrings` (`craft.*` + `app.*`), CraftUIKit-first, zero hardcoded strings.
- Quality gate `AGENTS.md §5`: `swiftlint` 0 warnings, `swift test` pass, Xcode 0 warnings.

---

## 3. System Architecture — Cloud-First

### 3.1 High-Level

```
[iOS App — VocabCraftApp (SwiftUI)]
  │  thin client, cache + offline queue
  │  APIClient (URLSession, JWT, Retry, ETag)
  ▼
[Caddy :80/:443 — TLS Let's Encrypt, reverse proxy /api → app:8000, /health → app:8000/health]
  ▼
[FastAPI Monolith :8000 — app/]
  ├─ modules/auth      (JWT access 15m / refresh 30d, bcrypt)
  ├─ modules/vocabulary (words, definitions, sentences, collocations)
  ├─ modules/decks      (topic_decks, topic_nodes, node_words)
  ├─ modules/progress   (user_word_progress, streaks, xp, attempts, weak words)
  ├─ modules/cms        (admin CRUD, review queue)
  └─ modules/pipeline   (crawler, normalizer, translator, AI reviewer — run as background job, not request path)
  ▼
[Postgres 16 :5432 — volume pgdata, Alembic migrations]
[Ollama :11434 — sidecar, models: qwen2.5:3b, nllb-200-600M]  (chỉ pipeline & CMS gọi, không phải runtime app)
```

So với `2026-08-31` spec (offline-first, local là source of truth): lần này **đảo invariant** — **server là source of truth**, local chỉ là **read-through cache + write-behind queue**. Quyết định này do user chọn **C. Cloud-first**, yêu cầu login ngay, đa thiết bị.

### 3.2 Repo Layout

```
vocab-craft-app/                     # iOS repo hiện tại (giữ nguyên)
  VocabCraftApp/
  Packages/CraftUIKit, SpeechKit
  docs/superpowers/specs/, plans/

vocab-craft-api/                     # mới — backend repo (đề xuất tách repo riêng để solo dev dễ CI)
  app/
    __init__.py
    main.py                          # create_app(), lifespan, CORS, X-Request-ID middleware
    core/
      config.py                      # pydantic-settings, .env
      db.py                          # SQLAlchemy async engine, session factory
      security.py                    # JWT (python-jose), bcrypt (passlib), API-Key guard cho CMS
      errors.py                      # error envelope, exception handlers
      pagination.py                  # cursor pagination helpers
      logging.py                     # structlog
    modules/
      auth/
        router.py, service.py, models.py, schemas.py, deps.py
      vocabulary/
        router.py, service.py, models.py, schemas.py
      decks/
        router.py, service.py, models.py, schemas.py
      progress/
        router.py, service.py, models.py, schemas.py, srs.py  # SRSEngine port sang Python
      cms/
        router.py, service.py, schemas.py  # admin-only
      pipeline/
        crawler.py, cleaner.py, normalizer.py, translator.py, reviewer.py, jobs.py
    api/
      v1/router.py                   # include all module routers under /api/v1
  alembic/
    env.py, versions/
  tests/
    test_auth.py, test_vocabulary.py, test_decks.py, test_progress.py, test_pipeline.py
  scripts/
    seed.py, crawl.py, import_wiktionary.py
  Dockerfile                         # python:3.12-slim, uv/pip
  docker-compose.yml                 # app, postgres, caddy, ollama
  .env.example
  openapi.json                       # generated, dùng để gen Swift DTOs
```

### 3.3 Runtime Self-Host (Mac mini M4)

- `docker compose up --build` — `app:8000`, `postgres:16` (volume `pgdata`), `caddy:80/443` (auto TLS), `ollama:11434` (volume `ollama_models`).
- Không Redis v1 — rate limit in-memory `slowapi` 100 req/60s/IP; thêm khi cần.
- Backup: `cron pg_dump -Fc > /backups/pg-$(date +%F).dump` daily, retain 7d, rclone offsite.
- Ollama models preload: `ollama pull qwen2.5:3b && ollama pull nllb-200-distilled-600M` (tổng <4GB, phù hợp M4 16GB). Pipeline gọi qua `http://ollama:11434/api/generate`, không expose ra ngoài.

### 3.4 iOS New Layers (tối thiểu đụng chạm)

```
VocabCraftApp/Core/Network/
  APIClient.swift                    # URLSession async/await, Endpoint enum, RequestBuilder, AuthInterceptor (refresh 401→ retry 1 lần), RetryPolicy exponential 1s/2s/4s, X-Request-ID
  AuthStore.swift                    # Keychain kSecClassGenericPassword (accessToken, refreshToken, userId)
  DTOs/                              # Codable ISO8601, gen từ openapi.json (openapi-generator-cli swift5)
    WordDTO.swift, DeckDTO.swift, ProgressDTO.swift, AuthDTO.swift
VocabCraftApp/Core/Sync/
  SyncEngine.swift                   # Cloud-first: push queue → POST, pull delta → GET, NWPathMonitor + BGTaskScheduler
  SyncOperation.swift                # SwiftData @Model persistent queue (survive kill)
  SyncMetadataStore.swift            # lastSyncToken (ISO8601 updated_at cursor) trong UserDefaults + SwiftData
  ConflictResolver.swift             # server-wins (cloud-first), khác với last-write-wins của offline-first cũ
VocabCraftApp/Core/Database/
  ContentCache.sqlite                # read-through cache cho words/decks (không phải source of truth)
  PendingOps.sqlite                  # queue cho progress writes khi offline
```

**Cloud-first invariant (khác 2026-08-31):** Mọi `recordReview`/`toggleBookmark`/`completeStage` phải gọi API trước khi coi là thành công. Nếu offline → enqueue vào `PendingOps`, UI hiển thị optimistic nhưng gắn badge `pending sync`, không tăng `masteryLevel` local vượt server version. Khi online → `SyncEngine` flush queue, server trả canonical `progress` mới, app overwrite local.

---

## 4. Data Models & API Contract

### 4.1 Postgres Schema (v1 — đủ cho 3000 từ + progress mở rộng)

```sql
-- Content (public, versioned, soft-delete, chỉ human_approved mới public)
words(
  id BIGINT PRIMARY KEY,                    -- giữ id Int64 tương thích Word.swift:5
  lemma TEXT NOT NULL UNIQUE,
  pos TEXT,                                 -- noun/verb/adj/...
  ipa_us TEXT, ipa_uk TEXT,
  cefr_level TEXT CHECK (cefr_level IN ('A1','A2','B1','B2','C1','C2')),
  frequency_rank INT,                       -- từ wordfreq, để sort/prioritize
  audio_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','ai_reviewed','human_approved','rejected')),
  ai_confidence DOUBLE PRECISION,            -- 0..1 từ reviewer model
  source_url TEXT,                          -- provenance
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ
);
definitions(
  id BIGINT PRIMARY KEY,
  word_id BIGINT NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  pos TEXT,
  definition_en TEXT NOT NULL,
  definition_vi TEXT,                       -- human hoặc NLLB
  definition_vi_auto TEXT,                  -- raw NLLB để so sánh
  example_en TEXT,
  example_vi TEXT,
  collocation_en TEXT,                      -- ví dụ: "make a decision"
  collocation_vi TEXT,
  source_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ
);
sentences(
  id BIGINT PRIMARY KEY,
  word_id BIGINT REFERENCES words(id) ON DELETE SET NULL,
  text_en TEXT NOT NULL,
  text_vi TEXT,
  cefr_level TEXT,
  source TEXT,                              -- tatoeba, wiktionary example
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
reflex_drills(
  id BIGINT PRIMARY KEY,
  sentence_id BIGINT REFERENCES sentences(id),
  drill_type TEXT NOT NULL,                 -- recall/collocation/produce/shadow
  prompt_text TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  distractors_json JSONB NOT NULL DEFAULT '[]',
  target_time_ms INT NOT NULL
);

-- Decks
topic_decks(
  id TEXT PRIMARY KEY,                      -- giữ String id như TopicDeckEntities
  title TEXT NOT NULL,
  title_vi TEXT,
  icon_name TEXT,
  badge_color_hex TEXT,
  cefr_level TEXT,
  sort_order INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'human_approved',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ
);
topic_nodes(
  id TEXT PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES topic_decks(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  title_vi TEXT,
  icon_name TEXT,
  sort_order INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ
);
node_words(
  node_id TEXT NOT NULL REFERENCES topic_nodes(id) ON DELETE CASCADE,
  word_id BIGINT NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  sort_order INT NOT NULL DEFAULT 0,
  PRIMARY KEY (node_id, word_id)
);

-- Content manifest (để app check delta nhanh)
content_manifest(
  version INT PRIMARY KEY,
  checksum TEXT NOT NULL,
  total_words INT NOT NULL,
  total_decks INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Users & Progress (cloud source of truth)
users(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
user_word_progress(
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id BIGINT NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  mastery_level INT NOT NULL DEFAULT 0 CHECK (mastery_level BETWEEN 0 AND 5),
  ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
  interval_days INT NOT NULL DEFAULT 1,
  next_review_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_review_date TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_bookmarked BOOLEAN NOT NULL DEFAULT false,
  mistake_count INT NOT NULL DEFAULT 0,
  consecutive_streak INT NOT NULL DEFAULT 0,
  practiced_modes TEXT NOT NULL DEFAULT '',          -- csv như practicedModesRaw
  mode_success_counts TEXT NOT NULL DEFAULT '',      -- ModeSuccessStatsCodec encode
  is_mastered BOOLEAN NOT NULL DEFAULT false,
  source_deck_id TEXT REFERENCES topic_decks(id),
  source_node_id TEXT REFERENCES topic_nodes(id),
  total_reviews INT NOT NULL DEFAULT 0,
  version INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, word_id)
);
CREATE INDEX idx_user_word_progress_next_review ON user_word_progress(user_id, next_review_date) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_word_progress_updated_at ON user_word_progress(updated_at);

user_stage_progress(
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  stage_id TEXT NOT NULL,                   -- SubTopicStage.id
  deck_id TEXT NOT NULL REFERENCES topic_decks(id),
  is_completed BOOLEAN NOT NULL DEFAULT false,
  score INT NOT NULL DEFAULT 0,
  progress_fraction DOUBLE PRECISION NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  version INT NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, stage_id)
);

quick_reflex_attempts(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id BIGINT NOT NULL REFERENCES words(id),
  drill_type TEXT NOT NULL,
  recall_time_ms INT,
  collocation_time_ms INT,
  produce_time_ms INT,
  recall_ok BOOLEAN, collocation_ok BOOLEAN, produce_ok BOOLEAN,
  shadow_score DOUBLE PRECISION,
  hint_level INT NOT NULL DEFAULT 0,
  input_mode TEXT NOT NULL,                 -- typing/speaking/multipleChoice
  retry_count INT NOT NULL DEFAULT 0,
  confidence TEXT NOT NULL,                 -- high/medium/low
  is_correct BOOLEAN NOT NULL,
  response_time_ms INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_attempts_user_word ON quick_reflex_attempts(user_id, word_id, created_at DESC);

streaks(
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  current_streak INT NOT NULL DEFAULT 0,
  longest_streak INT NOT NULL DEFAULT 0,
  last_active_date DATE,
  total_xp INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Pipeline review queue (internal)
pipeline_jobs(
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lemma TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','crawling','normalizing','translating','ai_reviewing','human_queue','approved','rejected')),
  raw_payload JSONB,
  normalized_payload JSONB,
  ai_review JSONB,                          -- {confidence, issues[], suggested_fix}
  assigned_to TEXT,                         -- admin email khi human review
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Mapping iOS: `Word.swift:4` (`Word` struct) ↔ `words` + `definitions`; `TopicDeckEntities` ↔ `topic_decks`/`topic_nodes`; `UserWordProgressData:27` ↔ `user_word_progress`; thêm `version/updatedAt` vào SwiftData `SchemaV3` khi cache.

### 4.2 API Contract `/api/v1` (OpenAPI 3.1, Pydantic v2 → Swift Codable ISO8601 + Cursor Pagination)

**Auth (public):**
- `POST /auth/register {email, password, display_name?}` → `201 {access_token, refresh_token, user: {id, email}}` | `409 EMAIL_EXISTS`
- `POST /auth/login {email, password}` → `200 {access_token, refresh_token, user}` | `401 INVALID_CREDENTIALS`
- `POST /auth/refresh {refresh_token}` → `200 {access_token, refresh_token}` | `401`
- `POST /auth/logout` (Bearer) → `204`
- `GET /auth/me` (Bearer) → `200 {id, email, display_name}`

**Content (public, ETag + Cache-Control: public, max-age=300, chỉ trả human_approved):**
- `GET /content/manifest` → `200 {version, checksum, total_words, total_decks, created_at}`
- `GET /content/decks` → `200 [TopicDeckDTO]` (sort_order ASC)
- `GET /content/decks/{id}` → `200 TopicDeckDTO` | `404`
- `GET /content/decks/{id}/nodes` → `200 [TopicNodeDTO]`
- `GET /content/nodes/{id}/words` → `200 [WordDTO]` (kèm bookmark/mastery nếu có Bearer, nếu không thì is_bookmarked=false)
- `GET /content/words?limit=50&offset=0&cefr=B2&q=algorithm` → `200 {items: [WordDTO], total, has_more}` (FTS sau, v1 dùng ILIKE)
- `GET /content/words/{id}` → `200 WordDTO` | `404`
- `GET /content/words/{id}/sentences` → `200 [SentenceDTO]`
- `GET /content/sync?since_version=12` → `200 {decks: [], nodes: [], words: [], deleted: {decks:[], nodes:[], words:[]}, new_version: 13}` (delta cho cache)

**Progress (Bearer required, server là source of truth):**
- `GET /progress/words` → `200 [UserWordProgressDTO]` (của user hiện tại, hỗ trợ `?word_ids=1,2,3` để hydrate)
- `GET /progress/words/{word_id}` → `200 UserWordProgressDTO` | `404` (chưa học → trả default mastery 0)
- `POST /progress/words/{word_id}/review {is_correct, response_time_ms, drill_type?, hint_level?}` → `200 {progress: UserWordProgressDTO, srs: {next_mastery, ease_factor, interval_days, next_review_date}, streak: {current, longest}, xp_delta}` (server chạy `SRSEngine` port sang Python, bump version, tính next_review)
- `POST /progress/words/{word_id}/bookmark` → `200 {is_bookmarked: bool, progress: UserWordProgressDTO}` (toggle, idempotent)
- `POST /progress/words/{word_id}/drill {is_correct, new_streak, new_modes, is_mastered, mode_stats?}` → `200 UserWordProgressDTO` (cho ReflexBlitz/Mixed)
- `POST /progress/stages/{stage_id}/complete {deck_id, score?, progress_fraction?}` → `200 UserStageProgressDTO`
- `GET /progress/summary` → `200 {total_learned, total_bookmarked, total_reviews, current_streak, longest_streak, total_xp, next_reviews: [WordDTO]}`
- `GET /progress/history?word_id=123&limit=20` → `200 [AttemptDTO]` (phục vụ weak words, analytics)
- `POST /progress/sync/push {operations: [{op_id: uuid, type: "review|bookmark|drill|stage_complete", payload: {...}, client_version}]}` → `200 {acks: [op_id], conflicts: [{op_id, server_progress}]}` (cho offline queue flush, server-wins)
- `GET /progress/sync/pull?since=2026-09-01T00:00:00Z` → `200 {changes: {word_progress: [], stage_progress: []}, new_token: ISO8601, has_more: bool}` (cursor = max updated_at)

**CMS (Admin, API-Key `X-Admin-Key` + Bearer admin role):**
- `GET /admin/pipeline/jobs?status=human_queue&limit=20` → `200 [PipelineJobDTO]`
- `POST /admin/pipeline/jobs/{id}/approve` → `200` (chuyển words/definitions status → human_approved, bump content_manifest version)
- `POST /admin/pipeline/jobs/{id}/reject {reason}` → `200`
- `POST /admin/content/import` `multipart {file: csv/json}` → `200 {imported: 120, new_version: 13}` (idempotent upsert)
- `POST /admin/decks` / `PUT /admin/decks/{id}` / `DELETE /admin/decks/{id}` (tương tự nodes, words)

**Error envelope (thống nhất):**
```json
{
  "code": "AUTH_EXPIRED | VALIDATION_ERROR | CONFLICT | NOT_FOUND | RATE_LIMITED",
  "message": "human readable",
  "details": {"field": "reason"},
  "request_id": "uuid"
}
```
Kèm header `X-Request-ID`. Swift `APIClient` map thành `APIError` enum.

**OpenAPI → Swift:** `openapi-generator-cli generate -i vocab-craft-api/openapi.json -g swift5 -o VocabCraftApp/Core/Network/Generated --additional-properties useClasses=false,generateModelAdditionalProperties=false` hoặc dùng `CreateAPI`/`swift-openapi-generator`. DTOs dùng `ISO8601DateFormatter` + `Codable`.

---

## 5. Service Boundaries — Tách Biệt Rõ

| Service | Trách nhiệm | Không làm |
|---------|-------------|-----------|
| **AuthService** | register/login/refresh, JWT sign/verify, bcrypt, `users` table, rate limit login | Không đụng content/progress |
| **VocabularyService** | CRUD words/definitions/sentences, search, FTS, `status` filter, version bump, manifest | Không tính SRS, không auth |
| **DeckService** | topic_decks/nodes/node_words, sort_order, deck progress aggregation (computed từ progress) | Không lưu mastery |
| **ProgressService** | SRS tính toán (`srs.py` port `SRSEngine.swift:15`), mastery/ease/interval/next_review, streak/xp, bookmark, weak-words query, history | Không serve content raw |
| **CmsService** | admin guard, review queue, approve/reject, import, content versioning | Không gọi Ollama trực tiếp (giao pipeline) |
| **PipelineWorker** | crawl → clean → normalize → translate → AI review → enqueue human_queue (async job, không block request) | Không expose public API, chỉ `POST /admin/pipeline/trigger` |

Dependency rule: `progress` → đọc `words` (FK check) nhưng không ghi `words`; `cms` → ghi `words/definitions`; `pipeline` → ghi `pipeline_jobs` + draft `words` (pending). Tất cả qua `core/db.py` session.

---

## 6. Dataset Pipeline — 0 Đồng API Bên Thứ 3 (Mac mini M4 + Ollama)

**Mục tiêu:** ≥3000 từ tần suất cao, CEFR A1-B2 trước, nguồn uy tín, không trả tiền dịch/API.

### 6.1 Nguồn

- **Frequency list:** `wordfreq` top 5000 en, lọc stopwords, lấy top 3000.
- **Definition/Example:** Wiktionary dump (enwiktionary-latest-pages-articles.xml.bz2, CC-BY-SA), Oxford 3000 wordlist (public domain extract), Tatoeba sentences (CC-BY).
- **IPA:** `epitran` hoặc `eng_to_ipa` (rule-based, không gọi API).
- **CEFR:** heuristic `wordfreq` + `cefr_classifier` (train nhẹ trên Cambridge Vocabulary Profile public list, không gọi LLM).
- **Dịch VI:** `nllb-200-distilled-600M` local (Ollama hoặc `transformers` local), fallback không dùng Google Translate API.

### 6.2 Pipeline DAG (mỗi lemma 1 job)

```
1. Crawler (Trafilatura + BeautifulSoup)
   input: lemma
   output: raw_html, raw_definition_en, raw_example_en, source_url
   libs: trafilatura, requests, lxml

2. Cleaner
   input: raw
   output: cleaned_en (strip HTML, normalize whitespace, langdetect filter en, dedup)
   libs: clean-text, ftfy

3. Normalizer
   input: cleaned_en, lemma
   output: pos (spaCy en_core_web_sm), ipa_us (epitran), cefr_level (heuristic), frequency_rank (wordfreq)
   libs: spacy, epitran, wordfreq

4. Translator (NLLB local)
   input: definition_en, example_en, collocation_en
   output: definition_vi_auto, example_vi_auto, collocation_vi_auto
   model: nllb-200-distilled-600M via Ollama hoặc transformers pipeline

5. AI Reviewer (Qwen2.5:3b via Ollama)
   prompt: "Bạn là biên tập từ điển. Đánh giá entry sau: lemma={lemma}, pos={pos}, definition_en={def}, example_en={ex}, cefr={cefr}. Trả về JSON: {confidence: 0..1, issues: [string], suggested_definition_vi, suggested_example_vi, cefr_correct: bool}"
   output: ai_review {confidence, issues, suggested_*, cefr_correct}
   routing: confidence >=0.75 → `ai_reviewed` (chờ human batch, ưu tiên thấp), <0.75 → `human_queue` ưu tiên cao (cần human duyệt ngay); chưa auto-approve ở bước này

6. Human Queue (CMS)
   admin duyệt: approve → words/definitions status=human_approved, bump content_manifest.version
               reject → status=rejected, ghi reason, job closed
   CMS UI: FastAPI Jinja admin hoặc Retool self-host, hiển thị ai_review + side-by-side EN/VI
```

### 6.3 Thực thi

- **Job runner:** `APScheduler` hoặc `arq` (Redis-free, dùng Postgres `pipeline_jobs` polling mỗi 5s) — đơn giản cho solo dev. Trigger: `POST /admin/pipeline/trigger {lemmas: ["abandon", ...]}` hoặc `scripts/crawl.py --limit 100`.
- **Batch:** 50 lemmas/lần, Ollama `num_ctx 2048`, `temperature 0.2` để determinist.
- **Storage:** `pipeline_jobs.raw_payload/normalized_payload/ai_review` JSONB để audit.
- **Quality gate trước release:** random sample 10% (300 từ) human duyệt 100% bất kể confidence; 90% còn lại: confidence ≥0.85 mới được auto-approve lên `human_approved` không cần human, 0.75–0.84 vẫn phải qua human_queue (batch duyệt nhanh), <0.75 bắt buộc human duyệt chi tiết; tổng `human_approved` phải ≥3000.

### 6.4 Seed 3000 từ — Thứ tự

- Wave 1 (1000): A1-A2 core (Oxford 3000 A1+A2 intersection với wordfreq top 1500).
- Wave 2 (1000): B1 (wordfreq 1500-2500).
- Wave 3 (1000): B2 (wordfreq 2500-4000, lọc academic).

---

## 7. iOS App Integration — Cloud-First, Giữ Clean Architecture

### 7.1 Thay Đổi Tối Thiểu

- Giữ `Domain/Protocols/*` (đã có `UserProgressRepositoryProtocol:4`, `VocabularyRepositoryProtocol`, `SRSRepositoryProtocol`, `DatasetDataSourceProtocol`).
- Thêm `RemoteVocabularyRepository: VocabularyRepositoryProtocol` (gọi `APIClient`), `RemoteProgressRepository: UserProgressRepositoryProtocol + SRSRepositoryProtocol` (gọi `/progress/*`), `RemoteDeckRepository`.
- `AppContainer.swift:7` thêm `apiClient: APIClient`, `authStore: AuthStore`, `syncEngine: SyncEngine`; `init(useMockData, apiBaseURL)` để `VocabCraftAppTests` vẫn dùng Mock.
- Không đụng ViewModel: `HomepageViewModel`, `TopicDecksViewModel`, `ReflexBlitzViewModel` vẫn gọi UseCase như cũ, UseCase gọi Repository mới.

### 7.2 APIClient Chi Tiết

```swift
enum Endpoint { case login, register, refresh, decks, words(limit: Int, q: String?), word(id: Int64), review(wordId: Int64), bookmark(wordId: Int64) }
struct APIClient {
  func request<T: Decodable>(_ endpoint: Endpoint, body: Encodable?) async throws -> T
  // - URLRequest + JSONEncoder ISO8601
  // - AuthInterceptor: gắn Bearer, nếu 401 → refresh (1 lần) → retry
  // - RetryPolicy: 429/5xx exponential 1s/2s/4s, respect Retry-After
  // - X-Request-ID: UUID per request
}
```

### 7.3 Sync & Offline (Cloud-First Queue)

- **Write path:**
  1. User tap `markWordReviewed` → ViewModel gọi `EvaluateSRSUseCase.recordReview` (đang `SRSRepositoryImpl` local) → đổi thành `RemoteProgressRepository.review` → `POST /progress/words/{id}/review`.
  2. Nếu online thành công → server trả canonical `progress` + `next_review_date`, app upsert vào `ContentCache.sqlite` (để UI đọc) và `SwiftData` (để widget).
  3. Nếu offline → enqueue `SyncOperation(type: .review, payload: {wordId, isCorrect, responseTimeMs}, createdAt)` vào SwiftData `PendingOps`, UI optimistic (hiển thị pending badge), không bump mastery local.

- **Flush queue:**
  - Trigger: `NWPathMonitor` → satisfied, `scenePhase == .active`, sau mỗi enqueue, `BGTaskScheduler` 15m nếu có pending.
  - `SyncEngine.flush(limit: 50)` → `POST /progress/sync/push {operations}` → server `ack` + `conflicts` (server-wins, overwrite local với server_progress).

- **Pull delta:**
  - `GET /progress/sync/pull?since=lastSyncToken` (token = max `updated_at` đã nhận, lưu `SyncMetadataStore` UserDefaults + SwiftData atomic).
  - Upsert vào local cache trên background `ModelActor`. Loop nếu `has_more`.

- **Content cache:**
  - `GET /content/manifest` so `localVersion` (UserDefaults `content_version`) với `server.version`. Nếu local < server → `GET /content/sync?since_version=localVersion` → upsert `ContentCache.sqlite`. Fallback bundle khi offline.
  - Check khi `app.foreground` + daily `BGTask`.

- **Conflict:** Cloud-first → **server-wins**. Nếu client gửi `client_version < server.version` → server trả `conflicts`, client discard local, apply server. Không merge easeFactor ở v1.

### 7.4 Widget & Notifications

- `WidgetCurrentState` trong App Group `group.com.hoojinguyen.vocabcraft` vẫn update từ local cache sau pull.
- `SyncEngine` sau khi pull xong → `WidgetCenter.shared.reloadTimelines()`. Silent APNs `content-available:1` (khi CMS bump manifest) trigger `BGTask` pull (optional v1).

### 7.5 Bảo Mật

- Keychain `kSecClassGenericPassword` cho tokens, `kSecAttrAccessibleAfterFirstUnlock`.
- Không lưu password.
- CMS admin key: `X-Admin-Key` env `ADMIN_API_KEY` (32+ chars), chỉ Mac mini biết.

---

## 8. Lộ Trình — 2 Tháng Solo + AI Post-Release

### 8.1 Wave Plan (1pt ≈ 3h, tổng ~90pt cho 2 tháng, 15h/tuần)

**Tháng 1 — Dataset + API Core (để có 1000 từ đầu)**

- **W1 (15pt):**
  - A1 `5pt` Scaffold vocab-craft-api (FastAPI modular, docker-compose app+postgres+caddy+ollama, Alembic, /health, structlog, X-Request-ID)
  - A2 `3pt` Auth (register/login/refresh, JWT, bcrypt, users table, tests)
  - B1 `5pt` DB schema words/definitions/sentences/topic_decks/nodes (Alembic V1), Pydantic schemas
  - D1 `2pt` iOS `APIClient` + `AuthStore` (Keychain) + DTOs gen

- **W2 (15pt):**
  - B2 `5pt` Content CRUD `GET /content/*` + manifest + ETag (public, human_approved filter)
  - P1 `5pt` Pipeline skeleton (crawler + cleaner + normalizer) + `pipeline_jobs` table + `POST /admin/pipeline/trigger`
  - P2 `3pt` Translator NLLB local (Ollama) integration, test 50 lemmas
  - D2 `2pt` iOS `RemoteVocabularyRepository` (thay DatasetEngine), `AppContainer` wiring

- **W3 (15pt):**
  - P3 `5pt` AI Reviewer Qwen2.5:3b (prompt, JSON parse, confidence), CMS review queue API `GET /admin/pipeline/jobs`
  - B3 `3pt` CMS approve/reject → bump manifest version, admin guard
  - C1 `5pt` ProgressService `POST /progress/words/{id}/review` (port SRSEngine sang `srs.py`, next_review, version bump)
  - D3 `2pt` iOS `RemoteProgressRepository` (review/bookmark), wiring `EvaluateSRSUseCase`

- **W4 (15pt):**
  - C2 `5pt` Progress còn lại (bookmark, drill, stage_complete, summary, history, streak/xp)
  - P4 `5pt` Wave 1 seed 1000 từ (A1-A2): crawl Wiktionary+Tatoeba, run pipeline, human review sample 100% cho 300 từ đầu, còn lại threshold 0.75
  - D4 `3pt` iOS Decks API (`RemoteDeckRepository`, TopicDecksViewModel)
  - E1 `2pt` Tests backend pytest >70% cho auth/content/progress

**Tháng 2 — Đủ 3000 Từ + Sync + Release**

- **W5 (15pt):**
  - P5 `5pt` Wave 2 seed 1000 từ B1 (pipeline batch 50, Ollama tuning)
  - C3 `5pt` SyncEngine iOS (queue, NWPathMonitor, BGTask, flush/push, server-wins)
  - C4 `3pt` Content sync delta `GET /content/sync?since_version` + `ContentCache.sqlite`
  - E2 `2pt` Fix bugs AppContainer:78, D2 actor refactor, SharedAppGroupContainer backup

- **W6 (15pt):**
  - P6 `5pt` Wave 3 seed 1000 từ B2, quality gate 10% random human review, tổng ≥3000 human_approved
  - C5 `3pt` Pull `GET /progress/sync/pull?since` + `SyncMetadataStore`
  - D5 `3pt` Offline queue UI (pending badge), error envelope, retry
  - E3 `2pt` `swiftlint` 0, `swift test` pass, build <15s, TestFlight internal

- **W7-8 buffer (10pt):**
  - CMS polish (Jinja admin UI hoặc Retool, import CSV, deck management)
  - Content expansion decks 4→8 (Du lịch, IELTS Speaking P2, TOEIC) via import
  - Backup cron, Caddy TLS, docs `openapi.json`, README self-host

**Post-release AI (phase 2-4, sau khi có user):**
- Phase 2 (1 tháng sau release): Adaptive SRS — server train nhẹ trên `quick_reflex_attempts` (không LLM, chỉ logistic regression điều chỉnh easeFactor theo `response_time + hint_level + retry_count`), A/B test.
- Phase 3: Pronunciation v2 — `SpeechKit` đã có, thêm server feedback chi tiết (không gọi API bên ngoài, dùng local Wav2Vec2 small).
- Phase 4: Chat role-play — host Qwen 7B trên Mac mini, stream qua `POST /ai/chat` (SSE), chỉ khi đã có >1000 DAU.

### 8.2 YAGNI — Đã Cắt

- Không Redis, không Celery, không k8s, không microservices.
- Không FTS5 v1 (chỉ ILIKE), không Realtime, không leaderboard server.
- Không train LLM riêng ở v1, chỉ dùng Ollama inference.

---

## 9. Error Handling, Testing & Quality

**Error handling:**
- Backend: `HTTPException` với `code` enum, `X-Request-ID` mọi response, 5xx log structlog + không leak stack.
- iOS: `APIError` (`.authExpired`, `.validation`, `.conflict(serverProgress)`, `.notFound`, `.rateLimited(retryAfter)`, `.network`), ViewModel map thành `CraftToast`/`CraftDialog`.
- Offline: mọi write fail → enqueue, không crash, không mất data (queue persistent).

**Testing:**
- Backend: `pytest` + `httpx.AsyncClient` + `pytest-asyncio`, coverage >70% cho auth/content/progress, test `srs.py` port chính xác `SRSEngine.swift:15`.
- iOS: `VocabCraftAppTests` mock `APIClient` (protocol) để test offline queue, `LocalizationTests` bilingual parity.
- E2E: `scripts/seed.py` tạo user test, seed 10 từ, chạy `curl` register→login→review→pull.

**Quality gate:**
- `docker compose up` pass, `/health` 200, `/content/manifest` ETag, `pytest` pass, `ruff`/`mypy` pass.
- iOS offline: airplane mode vẫn đọc 3000 từ cache, online flush 50 ops <2s, conflict 0 data loss, `swiftlint` 0, Xcode 0 warnings.

---

## 10. Risks & Mitigations

- **Solo sync complexity** → Cloud-first server-wins đơn giản hơn offline-first merge; chỉ flush queue, không merge phức tạp.
- **Ollama M4 memory** → chỉ chạy 1 model tại 1 thời điểm (queue), `qwen2.5:3b` (<2GB) + `nllb-600M` (<1GB), không load đồng thời.
- **Crawl legal/quality** → chỉ nguồn CC-BY-SA/CC-BY, ghi `source_url`, filter langdetect, human review gate 10%.
- **Self-host ops** → Docker Compose single VPS, backup pg_dump daily, Caddy auto-TLS; chưa cần k8s.
- **Content scale 3000 từ** → import idempotent `ON CONFLICT DO UPDATE WHERE version < excluded.version`, manifest version bump.

---

## 11. Success Criteria (v1 Release)

- API `docker compose up` trên Mac mini M4 pass, `openapi.json` gen ra Swift DTOs, `pytest` >70%.
- CMS duyệt được 3000 từ, mỗi từ có EN/VI definition + example + IPA + CEFR, `status=human_approved` ≥3000, manifest `total_words=3000`.
- iOS TestFlight: login/register hoạt động, học 3000 từ qua decks/nodes, progress (mastery/SRS/bookmark/streak) persist server, airplane mode đọc cache, online sync <2s/50 ops, `swift test` 100% pass, `swiftlint` 0.
- Backlog 31 tickets → map sang wave W1-W8, mỗi ticket ≤8pt.

---

## 12. References

- Current: `VocabCraftApp/App/DI/AppContainer.swift`, `VocabCraftApp/Core/Database/DatasetEngine.swift`, `VocabCraftApp/Core/SRS/SRSEngine.swift`, `VocabCraftApp/Domain/Protocols/*`, `VocabCraftApp/Data/Local/Actors/UserProgressModelActor.swift`, `docs/build-optimization.md`, `Package.swift`.
- Previous spec: `docs/superpowers/specs/2026-08-31-vocabcraft-backend-platform-design.md` (offline-first, nay superseded).
- Skills: `swift-architecture`, `swift-concurrency`, `swiftdata-pro`, `xcode-build-orchestrator`, `swiftlint`, `swift-testing`.

