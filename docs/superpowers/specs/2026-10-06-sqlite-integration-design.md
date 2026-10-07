# SQLite Content Integration Design

## 1. Overview
Replace the mock JSON-based `BundledVocabularyDataSource` with a production-ready `SQLiteVocabularyDataSource` backed by the `vocab_content.sqlite` v2.0.0 release.

## 2. Architecture & Components
- **`SQLiteVocabularyDataSource`**: A new class implementing `VocabularyDataSourceProtocol`. It uses Apple's native `SQLite3` C-API framework to perform read-only queries against the database.
- **`ContentBundleManager` (or similar utility)**: Responsible for checking if `vocab_content.sqlite` exists in the `Application Support/VocabCraft/Content/v4/` directory on app launch. If not, it copies it from the main bundle.
- **`AppContainer` Wiring**: Updated to initialize `SQLiteVocabularyDataSource` instead of `BundledVocabularyDataSource` when `useSampleData` is false (or unconditionally as the default production source).

## 3. Data Mapping & Queries
Since the protocol expects DTOs with specific types (like `TopicWordDTO` with `Int64` IDs), we map the relational SQLite tables to the expected shapes:
- **Decks (`TopicDeckDTO`)**: Queries `decks` table.
- **Stages (`SubTopicStageDTO`)**: Queries `lessons` table filtered by `deck_id`.
- **Words (`TopicWordDTO`)**: Queries `senses` joined with `entries`. We will use the SQLite implicit `rowid` of the `senses` table to populate the `Int64` `id` field. We will fetch pronunciations (IPA) and examples dynamically or via JOINs.
- **Search**: `searchWords` will use `LIKE` queries against `headword`, `lookup_key`, and definitions.

## 4. Error Handling & Validation
- **Database Open**: Read-only mode with `SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX`.
- **Validation**: On init, the repository will run `PRAGMA integrity_check` and `PRAGMA foreign_key_check` to ensure the file isn't corrupted.
- **Errors**: Maps SQLite errors to Swift errors, throwing safely.

## 5. Testing
- Run existing `VocabularyDataSourceProtocol` tests against the new implementation using the bundled SQLite file.
- Verify the specific query for the `essential-english-mastery` learning path to confirm the curriculum renders.
